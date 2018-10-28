# ansible-s3-ftp

DESCRIPTION: This soution builds reliable SFTP service using Amazon S3 bucket as a storage. 
Inspired by: https://cloudacademy.com/blog/s3-ftp-server/
 
 
This manual assumes you have AWS account and configured AWS CLI.


TO USE ansible role, build AWS resources using CloudFormation template:
1. indicate your AWS parameters in [SFTP-CLOUD.parameters.json]
2. run 'aws cloudformation create-stack' - see full command in [aws-cloudformation-masterfile.sh]


It will create following resources:
* AWS EC2 instance and keys pair.
* Public IP address assigned to EC2.
* Allowed INBOUND traffic to 990/tcp, 15390:15690/tcp in new EC2 secutiry group.
* S3 bucket as future SFTP storage.
* IAM Policy like AWS managed one "AmazonS3FullAccess" added to your ec2 instance.
* DNS entry for your hosted zone (template assumes that you have it).


HOW TO USE:
1. git clone to your local 'roles' folder
(you may want to symlink (ln -s) checked out repo to your 'roles' folder)
2. in roles/s3-ftp-server/vars/main.yml provide your bucket name, EIP and password hash values
3. to use role in playbook, use '/examples/sample_playbook’ as an example

NOTE:
The role was not designed as reusable. It didn’t fail after second run but re-usability was not tested.


REFERENCES:

1. https://cloudacademy.com/blog/s3-ftp-server/ 
2. https://github.com/s3fs-fuse/s3fs-fuse 
3. https://github.com/s3fs-fuse/s3fs-fuse/issues/602 
4. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
5. https://docs.aws.amazon.com/cli/latest/reference/cloudformation/index.html#cli-aws-cloudformation 
6. https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04 
7. https://stackoverflow.com/questions/7052875/setting-up-ftp-on-amazon-cloud-server 
