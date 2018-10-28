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
