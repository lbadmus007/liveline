# Associating VPCs with a Centralized Private Hosted Zone

## VPC Association request
The `centralized-phz-v2.yml` file will need to be run in the acccount where the private hosted domain exist.
A JSON formatted string for the AWS CloudFormation parameter `AccountVPCMappings` needs to be passed in. This paramter passes the target account VPCs and regions as a JSON string
A Lambda function is deploy which makes an API  call to all listed target accounts/VPCs for a phz asoociation request.

### Sample JSON String passed in ###
 `"{\"21000000000\":{\"VPCId\":\"vpc-00d2b000000000\",\"VPCRegion\":\"us-east-1\"},\"243000000000\":{\"VPCId\":\"vpc-0f35224000000000b\",\"VPCRegion\":\"us-east-2\"}}"`
 
 Please update the string with appropriate target account and vpc id's and the target regions for each vpc. Also note that the string can be extended to accomodate more vpc's. Finally, each item in the JSON stanza has to be escaped to allow CFN recongnize the string. 

At the completion of a successful deployment of the VPC association request CFN, a separate CFN `accept-vpc-assoc-to-phz.yml` needs to be deployed to each account that a request was made to. 

## VPC association to PHZ Acceptance
The `accept-vpc-assoc-to-phz.yml` has to be deployed to individual account  to be able to accept the association requesty to the private hosted zone.