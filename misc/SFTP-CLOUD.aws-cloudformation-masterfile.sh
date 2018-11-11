#!/bin/bash
#masterfile for SFTP manipulation - controls AWS resources creation, SFTP configuration
#usage: 
# --create_sftp  to create things
# --remove_sftp  to remove things

#parameters:
#stack name
sftp_stack_name=gSFTP-CLOUD
#set pass for user <ftpuser1> here
sftp_pass=ftppass1
what_we_do=$1
ansible_home=$ANSIBLE_HOME

programname=$0
usage() 
{
    echo "usage: $programname [--create-sftp --remove-sftp or --list-sftp/-h]"
    echo "  --create-sftp     Create AWS SFTP infrastructure and install vsftpd using ansible"
    echo "  --remove-sftp     Remove AWS SFTP infrastructure"
    echo "  --list-sftp       Describe AWS SFTP resources (stack)"
    echo "  -h      display help"
    exit 1
}


#CREATE
#1. this will create stack (similar command to update stack, see man)
stack_creation()
{
	aws cloudformation create-stack \
	--stack-name $sftp_stack_name \
	--template-body file://misc/SFTP-CLOUD.template \
	--parameters file://misc/SFTP-CLOUD.parameters.json \
	--capabilities CAPABILITY_NAMED_IAM \
	--tags Key=purpose,Value=sftp
}


#2. this will get stack status
stack_progress()
{
	stack_operations_inprogress=true

	while [ "${stack_operations_inprogress}" = "true" ]; do
		export stack_status=$(aws cloudformation describe-stacks --stack-name ${sftp_stack_name} --output json | grep StackStatus | awk {'print $2'} | sed -e 's/^"//' -e 's/",//')
		if [ "$stack_status" = 'CREATE_COMPLETE' ] || [ "$stack_status" = 'UPDATE_COMPLETE' ] || [ "$stack_status" = 'DELETE_COMPLETE' ]
		then 
			echo "stack ${sftp_stack_name} status is ${stack_status}" 
			stack_operations_inprogress=false
			sleep 4	
		else
			if [ "$stack_status" = 'CREATE_IN_PROGRESS' ] || [ "$stack_status" = 'UPDATE_IN_PROGRESS' ] || [ "$stack_status" = 'DELETE_IN_PROGRESS' ]
			then 
				echo "stack ${sftp_stack_name} status is ${stack_status}" 
				stack_operations_inprogress=true
				sleep 4
			else 
				echo "Error: stack operations error or stack does not exist - exiting" 
				break
			fi
		fi
	done
}


aws_cf_variables_to_ansible()
{
	#this will take params for ansible
	export SFTP_S3_BUCKET_ID=$(aws cloudformation describe-stacks --stack-name $sftp_stack_name --output text | grep S3bucketID | awk {'print $3'})
	export SFTP_PUBLIC_IP=$(aws cloudformation describe-stacks --stack-name $sftp_stack_name --output text | grep PublicIPAddress | awk {'print $3'})
	export SFTP_DNS=$(aws cloudformation describe-stacks --stack-name $sftp_stack_name --output text | grep DomainName | awk {'print $3'})

	#this will update known_hosts
	ssh-keyscan $SFTP_DNS >> ~/.ssh/known_hosts
	ssh-keyscan $SFTP_PUBLIC_IP >> ~/.ssh/known_hosts

	#this will generate password for SFtP user <ftpuser1>
	#usage: openssl passwd -salt <salt> -1 <password>
	export SFTP_PASS_HASH=$(openssl passwd -salt 990 -1 $sftp_pass)
}


#LIST
list_sftp_stack()
{
	aws cloudformation describe-stacks --stack-name ${sftp_stack_name}
}


#DELETE
#1. remove bucket 
s3_force_removal()
{
	aws s3 rb --force s3://${SFTP_S3_BUCKET_ID}
}


#2. clean known_hosts
#this helps when IP of ansible target server changes
sys_variables_cleanup()
{
	echo "remove sftp fqdn ($fqdn) and sftp ip ($ip) from known hosts"
	sed -i '/^'$SFTP_DNS'/d' ~/.ssh/known_hosts
	sed -i '/^'$SFTP_PUBLIC_IP'/d' ~/.ssh/known_hosts
	#this will remove variables from 'env'
	unset SFTP_S3_BUCKET_ID PUBLIC_IP SFTP_DNS SFTP_PASS_HASH
}


#3. delete stack
delete_sftp_stack()
{
	aws cloudformation delete-stack --stack-name $sftp_stack_name
}

main()
{
	if [ $what_we_do == '--create-sftp' ]
	then 
		stack_creation
		stack_progress
		aws_cf_variables_to_ansible
		ansible-playbook -i hosts playbooks/s3-ftp-server.yml
	
	elif [ $what_we_do == '--remove-sftp' ]
	then
		s3_force_removal
		sys_variables_cleanup
		delete_sftp_stack
		stack_progress
	elif [$what_we_do == '--list-sftp' ]
	then
		list_sftp_stack
	elif [ $what_we_do == '-h' ]
	then
		usage
	else
		usage
}


main
