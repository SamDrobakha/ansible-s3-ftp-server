#!/bin/bash

#this will create stack (similar command to update stack, see man)
aws cloudformation create-stack \
--stack-name gSFTP-CLOUD \
--template-body file://SFTP-CLOUD.template \
--parameters file://SFTP-CLOUD.parameters.json \
--capabilities CAPABILITY_NAMED_IAM \
--tags Key=purpose,Value=sftp

#this will delete stack
aws cloudformation delete-stack --stack-name gSFTP-CLOUD

#this will take params for ansible
export S3_BUCKET_ID=$(aws cloudformation describe-stacks --stack-name gSFTP-CLOUD --output text | grep S3bucketID | awk {'print $3'})
export PUBLIC_IP=$(aws cloudformation describe-stacks --stack-name gSFTP-CLOUD --output text | grep PublicIPAddress | awk {'print $3'})
export SFTP_DNS=$(aws cloudformation describe-stacks --stack-name gSFTP-CLOUD --output text | grep DomainName | awk {'print $3'})

