# Trying to be helpful

## Reference URLS

SSM Instance Profile
https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html#create-iam-instance-profile-ssn-logging

## Pre-Requisitives

Before starting registering the on-premises hosts, you need to populate 02 environment files for aws user authentication. 

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

Steps to be executed on Centralized/Destination Logging Account

```
- Deploy CFT 'CentralizedLoggingKinesis.yaml'

  # This will create Kinesis Firehose, CloudWatch Log Group Destination and their related components
```
  ### CFT is expecting below paramters to run, by default parameters values are present in it but update the same as per the requirement
```
  ## OrgId: AWS Organization Id
  ## CWLogsDestinationName: CloudWatch Log Group Destination Name
  ## KinesisLogGroupName: Kinesis CloudWatch Log Group Name
  ## KinesisLogStreamName: Kinesis CloudWatch Log Stream Name
  ## KinesisS3BucketPrefix: S3 bucket prefix name attached to Kinesis Firehose
  ## s3bucketname: S3 bucket name attached to Kinesis Firehose
```
Steps to be executed on Source AWS Account

```
- Deploy CFT 'SourceAccount.yaml'

  # This will create CloudWatch Log Group, KMS Key, IAM Role and their related components
```

  ### CFT is expecting below paramters to run, by default parameters values are present in it but update the same as per the requirement
```
  ## LogGroupName: CloudWatch Log Group name to which SSM logs will be forwarded
  ## CMKAliasName: KMS Key Alias name attached to KMS key
  ## SSMDocument: Name of SSM Document to trigger, contains CloudWatch Log forwarding configuration
  ## IAMRoleName: Name of an IAM role attached to Create Activations as well as to on-premises hosts
  ## LogPusherRoleName: Name of an IAM role used to push log events to the destination
```

Allow using Advanced Tier for on-premises activation under Source AWS Account

```
  ## Go to Service AWS System Manager -> Fleet Manager -> Settings -> Change Instance tier settings -> Accept the warning -> Click on Change setting
  ## You've to convert the standard to advanced-tier in order to interact with non-ec2 hosts

```

About SessionManagerRunShell.json

```
- Copy file SessionManagerRunShell.json to Source AWS Account

  # This json file contains cloudwatch log group configuration to which SSM logs will be forwarded
```

About create_activation_script.sh

```
- Copy file create_activation_script.sh to Source AWS Account

  # This shell script is used for creating the create-activation, helps in registering the on-premises hosts
```

  ### The shell script requires below 04 arguments 
```
  ## 1. CFT Name: Name of the CFT deployed on Source AWS Account
  ## 2. On-Premises Host Name: Name of on-premises host to be located under AWS Systems Manager [Fleet Manager] Console
  ## 3. Destination ARN: CloudWatch Logs Destination ARN [Pull the value from Outputs under deployed CentralizedLoggingKinesis.yaml CFT on Centralized/Destination Account]
  ## 4. IAM Role Arn: Log Pusher IAM Role ARN [Pull the value from Outputs under deployed SourceAccount.yaml CFT on Source AWS Account]

``` 
  ### Execute the shell script
```
  ## 1. chmod +x create_activation_script.sh SessionManagerRunShell.json
  ## 2. nohup ./create_activation_script.sh ARG1 ARG2 ARG3 ARG4 > create_activation_script.logs & 
  ## Example: nohup ./create_activation_script.sh CWLG OnPremisesHost arn:aws:logs:us-east-1:XXXXXXXX:destination:CentralisedLogss arn:aws:iam::XXXXXXXXXXXX:role/CentralisedLogsPusher > 
     create_activation_script.logs &
  
  ## Below areguments are required to run above shell script
  ## Arg1: Source Account CFN ARN
  ## Arg2: On-Premise Host Name to be registered using Create-Activation
  ## Arg3: Centralized/Destination Account Destionation ARN
  ## Arg4: Source Account Pusher IAM Role
  
```
  ### Verification Step
```
  ## Press ENTER post triggering the nohup command, the script will be executed in the background and store all the script execution logs to create_activation_script.logs file, look into this 
     for any success or failure.
  ## Once the script is successfully executed, an on-premise host id having prefix as 'mi-' will be visible to create_activation_script.logs file which despicts that the on-premise host has 
     been succesfully registered.
  ## The same mi-xx id would be visible to Fleet Manager under System Manager in Source AWS Account.
  ## Enable the SSM session for instance mi-xx and that session would be visible to Session Manager under System Manager with unique session id.
  ## Once the SSM session for instance mi-xx would be terminated, the session logs would be forwarded to the Source AWS Account CloudWatch Log Group as well as to the Centralized/Destination   
     Logging AWS Account S3 bucket.

``` 
