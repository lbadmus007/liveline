#!/bin/bash
###set -x

echo "Running the file: $0"

echo ".......... Downloading required packages ..........."
sudo yum update -y
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
        export role=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Outputs[0].OutputValue")
else
        echo "...... $1 cloudformation stack is not deployed deployed, exiting now ....."
        exit 1
fi

echo "............ Activating Hybrid Activation ................"
echo $role
export variable=$(aws ssm create-activation --default-instance-name "$2" --iam-role "$role" --registration-limit 1)

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

echo "Update fingerprint"
sudo amazon-ssm-agent -fingerprint -similarityThreshold 1

echo ".............. Synching Clock .................."
sed -i '1s/^/server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4 \n /' /etc/chrony.conf
sudo service chronyd restart
sudo chkconfig chronyd on
chronyc sources -v
chronyc tracking
echo ".............. Clock has been successfully synched with AWS ............."

echo "........... Updating cloudwatch log group and kms key details in SessionManagerRunShell.json file ..........."

export log_group=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Outputs[1].OutputValue")
export kms_key=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Outputs[2].OutputValue")

jq --arg newval "$log_group" '.inputs.cloudWatchLogGroupName |= $newval' SessionManagerRunShell.json > local_cache1.json
jq --arg newval "$kms_key" '.inputs.kmsKeyId |= $newval' local_cache1.json > local_cache2.json

mv -f local_cache2.json SessionManagerRunShell.json
rm local_cache1.json
#rm local_cache2.json

echo ".............. Updating the session manager preferences setting for cloudwatch log group ...................."
aws ssm update-document --name "SSM-SessionManagerRunShell" --content "file://SessionManagerRunShell.json" --document-version "\$LATEST"

echo $role

echo "............... Creating Subscription Filter for CloudWatch Log Group ......................"
aws logs put-subscription-filter --log-group-name $log_group --filter-name "CentralisedLogging" --filter-pattern '' --destination-arn "$3" --role-arn "$4"

echo "............ All steps are succesfully executed ..........."
