#!/bin/bash

echo "........... Initiating the execution ............".

export var=$(aws secretsmanager list-secrets --filter Key="description",Values="Auto-created secret" --query "SecretList[].Name" --output text)

#echo $var

for value in $var
do
        #echo $value
        if [[ "$value" == *LL_CloudWatch_AgentUser* ]]
        then
                echo "........... Reading access and secret keys from secret: $value"
                export new_access_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."AccessKeyId")
                export new_secret_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."SecretAccessKey")

                echo $new_access_key
                echo $new_secret_key

                echo "....... Replacing access and secret keys ..........."
                cat /home/cwagent/.aws/credentials
                sed -i -r -e "s:^(aws_access_key_id =).*:\1 $new_access_key:" -e "s:^(aws_secret_access_key =).*:\1 $new_secret_key:" /home/cwagent/.aws/credentials
                cat /home/cwagent/.aws/credentials
                echo "................................................................................................................................................"

        elif [[ "$value" == *InnovationOnPrem* ]]
        then
                echo "........... Reading access and secret keys from secret: $value"
                echo $value
                export new_access_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."AccessKeyId")
                export new_secret_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."SecretAccessKey")

                echo $new_access_key
                echo $new_secret_key

                echo "....... Replacing access and secret keys ..........."
                cat /home/innovation/.aws/credential
                sed -i -r -e "s:^(aws_access_key_id =).*:\1 $new_access_key:" -e "s:^(aws_secret_access_key =).*:\1 $new_secret_key:" /home/innovation/.aws/credential
                cat /home/innovation/.aws/credential
                echo "................................................................................................................................................"
        else
                echo "........... Reading access and secret keys from secret: $value"
                echo $value
                export new_access_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."AccessKeyId")
                export new_secret_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."SecretAccessKey")

                echo $new_access_key
                echo $new_secret_key

                echo "....... Replacing access and secret keys ..........."
                cat /etc/systemd/system/docker.service.d/override.conf
                sudo sed -i -r -e "s:^(aws_access_key_id =).*:\1 $new_access_key:" -e "s:^(aws_secret_access_key =).*:\1 $new_secret_key:" /etc/systemd/system/docker.service.d/override.conf
                systemctl reload docker
                systemctl restart docker
                cat /etc/systemd/system/docker.service.d/override.conf
        fi
done

echo ".................. Script Execution is Completed ................."