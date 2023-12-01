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

Steps to be executed on Centralized Logging Account

```
- Deploy CFT 'CentralizedLoggingKinesis.yaml'

  # This will create Kinesis Firehose, CloudWatch Log Group Destination and their related components

  # CFT is expecting below paramters to run, by default parameters default values are present in it but update the same as per the requirement

  ## OrgId: AWS Organization Id
  ## CWLogsDestinationName: CloudWatch Log Group Destination Name
  ## KinesisLogGroupName: Kinesis CloudWatch Log Group Name
  ## KinesisLogStreamName: Kinesis CloudWatch Log Stream Name
  ## KinesisS3BucketPrefix: S3 bucket prefix name attached to Kinesis Firehose
  ## s3bucketname: S3 bucket name attached to Kinesis Firehose
```

```
- Deploy CFT 'SourceAccount.yaml'

  # This will create CloudWatch Log Group, KMS Key, IAM Role and their related components

  # CFT is expecting below paramters to run, by default parameters default values are present in it but update the same as per the requirement

  ## **LogGroupName:** CloudWatch Log Group name to which SSM logs will be forwarded
  ## CMKAliasName: KMS Key Alias name attached to KMS key
  ## SSMDocument: Name of SSM Document to trigger, contains CloudWatch Log forwarding configuration
  ## IAMRoleName: Name of an IAM role attached to Create Activations as well as to on-premises hosts
  ## LogPusherRoleName: Name of an IAM role used to push log events to the destination
```


- Execute script.sh as per below command and a file named SessionManagerRunShell.json:
  # Add script.sh KMS ID parameter created in above step

- Deploy CFT 'CentralizedLoggingCWLDestination.yaml' to parent acc, it'll create a log destination and an iam role attached to it
  # It'll create cloudwatch logging destination

- Deploy CFT 'CentralizedLoggingKinesis - New.yaml' to parent acc, it'll create a kinesis firehost and firehost iam role
  # It'll create kinesis, lambda, and their related components

- Deploy CFT 'SourceAccCFT.yaml' to parent acc, it'll create a kinesis firehost and firehost iam role
  # It'll create log pusher IAM role for Cloudwatch subscription filter

- Trigger below AWS CLI command:
- aws logs put-subscription-filter --log-group-name /aws/ssm/SessionManagerLogg --filter-name CentralisedLogging --filter-pattern '' --destination-arn   
  arn:aws:logs:us-east-1:082494019291:destination:CentralisedLogss --role-arn arn:aws:iam::367521952991:role/CentralisedLogsPusher