#!/bin/bash

echo "........... Initiating the execution ............".

# List all secrets having specific description, access and secret keys are stored in aws secret manager
export var=$(aws secretsmanager list-secrets --filter Key="description",Values="Auto-created secret" --query "SecretList[].Name" --output text)

#echo $var
# Iterating secrets one-by-one, fetching keys, replace them in the different file locations
for value in $var
do
        #echo $value
        if [[ "$value" == *XYZ* ]]
        then
                echo "........... Reading access and secret keys from secret: $value"
                export new_access_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."AccessKeyId")
                export new_secret_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."SecretAccessKey")

                echo $new_access_key
                echo $new_secret_key

                echo "....... Replacing access and secret keys ..........."
                cat ~/.aws/credentials_1
                sed -i -r -e "s:^(aws_access_key_id =).*:\1 $new_access_key:" -e "s:^(aws_secret_access_key =).*:\1 $new_secret_key:" ~/.aws/credentials_1
                cat ~/.aws/credentials_1
                echo "................................................................................................................................................"

        elif [[ "$value" == *ABC* ]]
        then
                echo "........... Reading access and secret keys from secret: $value"
                echo $value
                export new_access_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."AccessKeyId")
                export new_secret_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."SecretAccessKey")

                echo $new_access_key
                echo $new_secret_key

                echo "....... Replacing access and secret keys ..........."
                cat ~/.aws/credentials_2
                sed -i -r -e "s:^(aws_access_key_id =).*:\1 $new_access_key:" -e "s:^(aws_secret_access_key =).*:\1 $new_secret_key:" ~/.aws/credentials_2
                cat ~/.aws/credentials_2
                echo "................................................................................................................................................"
        else
                echo "........... Reading access and secret keys from secret: $value"
                echo $value
                export new_access_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."AccessKeyId")
                export new_secret_key=$(aws secretsmanager get-secret-value --secret-id $value --output json | jq --raw-output .SecretString | jq -r ."SecretAccessKey")

                echo $new_access_key
                echo $new_secret_key

                echo "....... Replacing access and secret keys ..........."
                cat ~/.aws/credentials_3
                sed -i -r -e "s:^(aws_access_key_id =).*:\1 $new_access_key:" -e "s:^(aws_secret_access_key =).*:\1 $new_secret_key:" ~/.aws/credentials_3
                cat ~/.aws/credentials_3
        fi
done

echo ".................. Script Execution is Completed ................."
