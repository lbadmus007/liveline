#!/bin/bash
##set -x

echo "Running the file: $0"

echo ".......... Downloading required packages ..........."
yum update -y
sudo yum install curl -y
sudo yum install unzip -y
sudo yum install chrony -y
sudo yum install jq -y

echo ".............. Installing AWS CLI ..............."
aws_cli=/usr/local/bin/aws

if [ -h $aws_cli ]; then
        echo "aws cli is already installed"
else
        echo "aws cli is not installed....... installing now"
        yes Y | curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        chmod 777 awscliv2.zip
        unzip awscliv2.zip
        sudo ./aws/install
        /usr/local/bin/aws --version
fi

echo "........... Checking if cfn stack is already deployed or not ..........."
if aws cloudformation describe-stacks --stack-name $1; then
        echo "...... $1 cloudformation stack already deployed, fetching exported variables ....."
#       export log_group=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Outputs[1].OutputValue")
#       export kms_key=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Outputs[2].OutputValue")
        export role=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Outputs[0].OutputValue")
else
        echo "...... $1 cloudformation stack is not deployed deployed, exiting now ....."
        exit 1
fi

echo "............ Activating Hybrid Activation ................"
export variable=$(aws ssm create-activation --default-instance-name "OnPremisesHosts" --iam-role "$role" --registration-limit 1)
#echo $variable

export activation_id=$(echo $variable | cut -d' ' -f2)
export activation_code=$(echo $variable | cut -d' ' -f1)
echo $activation_id
echo $activation_code

echo "............ Fetching region value from aws profile ..............."
export aws_region=$(aws configure get region)
echo $aws_region

mkdir -p /tmp/ssm
curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm -o /tmp/ssm/amazon-ssm-agent.rpm
chmod 777 /tmp/ssm/amazon-ssm-agent.rpm
sudo yum install -y /tmp/ssm/amazon-ssm-agent.rpm
sudo systemctl stop amazon-ssm-agent
sudo -E amazon-ssm-agent -register -code $activation_code -id $activation_id -region $aws_region
sudo systemctl start amazon-ssm-agent

#echo "Update fingerprint"
#sudo amazon-ssm-agent -fingerprint -similarityThreshold 1

echo ".............. Synching Clock .................."
sed -i '1s/^/server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4 \n /' /etc/chrony.conf

sudo service chronyd restart
sudo chkconfig chronyd on
chronyc sources -v
chronyc tracking
echo ".............. Clock has been successfully synched with AWS ............."

instance_id=$(grep -i "Managed instance-id" AddSSMForOnPremise.logs | sed 's/.*: //')
s3keyname=$3/${instance_id}

echo "........... Updating KMS key, S3 Bucket and S3 Key Name[Prefix] in SessionManagerRunShell.json file ..........."
jq --arg newval "$2" '.inputs.s3BucketName |= $newval' SessionManagerRunShell.json > local_cache1.json
jq --arg newval "$s3keyname" '.inputs.s3KeyPrefix |= $newval' local_cache1.json > local_cache2.json
jq --arg newval "$4" '.inputs.kmsKeyId |= $newval' local_cache2.json > SessionManagerRunShell.json

echo ".............. Updating the session manager preferences setting for cloudwatch log group ...................."
aws ssm update-document --name "SSM-SessionManagerRunShell" --content "file://SessionManagerRunShell.json" --document-version "\$LATEST"

echo $role

echo "............ All steps are succesfully executed ..........."

rm local_cache1.json
rm local_cache2.json