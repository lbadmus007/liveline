# Trying to be helpful

## Reference URLS

SSM Instance Profile
https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html#create-iam-instance-profile-ssn-logging

## Pre-Requisitives

Before starting registering the on-premises hosts, you need to populate 02 environment files fur aws user authentication. 

The file you create is ignored by git, so there is no risk of accidentially committing secrets to the repo.(As long as the filename matches the .gitignore)

File: ~/.aws/credentials
```
[default]
aws_access_key_id     = XXXXXXX
aws_secret_access_key = xxxxxxx
....
```

File: ~/.aws/config 
```
[default]
region = us-east-1
output = text
....
```

### Implementation Steps



You may also want to run multiple docker containers simultaniously to make pipelines run in parallel. 

```
- Setup AWS profile as mentioned in above pre-requisitives

- Deploy CFT 'LoggingAccontCFT.yaml' to centralized logging aws account to which SSM session logs will be forwarded to
  # The template is fully dynamic and requires updated paramater values as per the deployment aws account

- Note down the S3 bucket name and KMS CMK ARN post deployment

- Deploy CFT 'AppAccountCFT.yaml' to application aws account from where the SSM session logs will be forwarded
  # The template is fully dynamic and required updated parameter values as per the deployment aws account

- Note down the CFT name post deployment

- Copy SessionManagerRunShell.json file to the application aws account on-premises linux machine

- Copy AddSSMForOnPremise.sh file to the application aws account on-premises linux machine and execute it as per below commands
  # chmod +x AddSSMForOnPremise.sh SessionManagerRunShell.json
  # nohup ./AddSSMForOnPremise.sh Liveline liveline-bucketdetailsss 367521952991 arn:aws:kms:us-east-1:082494019291:key/7be77241-dbf3-4255-af88-a7ecba80debf > AddSSMForOnPremise.logs &
  
  # The .sh file requires below 04 arguments:
  # 1 - Name of CFT deployed to application aws account
  # 2 - Name of S3 bucket created on centralized logging aws account
  # 3 - Application aws account ID
  # 4 - KMS CMK ARN deployed to centralized logging aws account
  
  # Press ENTER post triggering the above nohup command, the script will be executed in the background and store all the script execution logs to AddSSMForOnPremise.logs file, look into this #  
    for any success or failure
  
  # Once the script is successfully executed, a on-premise host id having prefix as 'mi-' will be visible to AddSSMForOnPremise.logs file which despicts that the on-premise host has been 
    succesfully registered
  
  # The same mi-xx id would be visible to Fleet Manager under System Manager in application aws account
  # Enable the SSM session for instance mi-xx and that session would be visible to Session Manager under System Manager
  # Once the SSM session for instance mi-xx would be terminated, the session logs would be forwarded to the centralized logging aws account S3 bucket under application aws account ID folder