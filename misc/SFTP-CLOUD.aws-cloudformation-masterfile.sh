#!/bin/bash

#set pass for user <ftpuser1> here
sftp_pass=ftppass1

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
export SFTP_S3_BUCKET_ID=$(aws cloudformation describe-stacks --stack-name gSFTP-CLOUD --output text | grep S3bucketID | awk {'print $3'})
export PUBLIC_IP=$(aws cloudformation describe-stacks --stack-name gSFTP-CLOUD --output text | grep PublicIPAddress | awk {'print $3'})
export SFTP_DNS=$(aws cloudformation describe-stacks --stack-name gSFTP-CLOUD --output text | grep DomainName | awk {'print $3'})

#this will generate password for SFtP user <ftpuser1>
#usage: openssl passwd -salt <salt> -1 <password>
export SFTP_PASS_HASH=$(openssl passwd -salt 990 -1 $sftp_pass)