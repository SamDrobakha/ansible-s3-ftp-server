# ansible-s3-ftp

## DESCRIPTION: This soution builds reliable SFTP service using Amazon S3 bucket as a storage. 
Inspired by: https://cloudacademy.com/blog/s3-ftp-server/
  
This manual assumes you have AWS account and configured AWS CLI.


## CREATES REQUIRED AWS RESOURCES ACCORDING TO SEPARATE TEMPLATE:

* AWS EC2 instance and keys pair.
* Public IP address assigned to EC2.
* Allowed INBOUND traffic to 990/tcp, 15390:15690/tcp in new EC2 secutiry group.
* S3 bucket as future SFTP storage.
* IAM Policy like AWS managed one "AmazonS3FullAccess" added to your ec2 instance.
* DNS entry for your hosted zone (template assumes that you have it).



## HOW TO USE:

1. git clone this repository to your ansible master machine
2. symlink it to your $ANSIBLE_HOME/roles directory
    ^ make sure $ANSIBLE_HOME is set
3. set your variables in misc/SFTP-CLOUD.parameters.json
4. symlink roles/s3-ftp-server/examples/s3-ftp-server.yml to $ANSIBLE_HOME/roles 
5. run misc/SFTP-CLOUD.aws-cloudformation-masterfile.sh –create-sftp from role directory (see script usage)




## REFERENCES:

1. https://cloudacademy.com/blog/s3-ftp-server/ 
2. https://github.com/s3fs-fuse/s3fs-fuse 
3. https://github.com/s3fs-fuse/s3fs-fuse/issues/602 
4. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
5. https://docs.aws.amazon.com/cli/latest/reference/cloudformation/index.html#cli-aws-cloudformation 
6. https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04 
7. https://stackoverflow.com/questions/7052875/setting-up-ftp-on-amazon-cloud-server 
