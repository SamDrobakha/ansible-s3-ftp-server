#!/bin/bash
#masterfile for SFTP manipulation - controls AWS resources creation, SFTP configuration
#usage: 
# --create_sftp        Create AWS SFTP infrastructure and install vsftpd using ansible
# --remove_sftp        Remove AWS SFTP infrastructure
# --list-sftp          Describe AWS SFTP resources (stack)
#--create-only-stack   Create AWS SFTP infrastructure (stack) only"
# -h                   Show help


#set stack name in misc/SFTP-CLOUD.parameters.json
sftp_stack_name=$(grep newStackName misc/SFTP-CLOUD.parameters.json | awk {'print $5'} | sed 's/"//g')
#set pass and user name in misc/SFTP-CLOUD.parameters.json
sftp_user=$(grep sftpUserName misc/SFTP-CLOUD.parameters.json | awk {'print $5'} | sed 's/"//g')
sftp_pass=$(grep sftpUserPass misc/SFTP-CLOUD.parameters.json | awk {'print $5'} | sed 's/"//g')

#SET ANSIBLE HOME HERE - it is usually required for ansible correct run
ansible_home=$ANSIBLE_HOME
what_we_do=$1
programname=$0


usage() 
{
    echo "usage: $programname [--create-sftp --remove-sftp --list-sftp -h]"
    echo ""
    echo "  --create-sftp         Create AWS SFTP infrastructure and install vsftpd using ansible"
    echo "  --remove-sftp         Remove AWS SFTP infrastructure"
    echo "  --list-sftp           Describe AWS SFTP resources (stack)"
    echo "  --create-only-stack   Create AWS SFTP infrastructure (stack) only"
    echo "  -h                    Show this message"
    exit 1
}


#CREATE
#1. this will create stack (similar command to update stack, see man)
stack_creation() 
{
	echo "$(date +"%Y-%m-%d %T") Starting stack creation"
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
	echo "$(date +"%Y-%m-%d %T") Starting stack progress check"
	stack_operations_inprogress=true

	while [ "${stack_operations_inprogress}" = "true" ]; do
		export stack_status=$(aws cloudformation describe-stacks --stack-name ${sftp_stack_name} --output json | grep StackStatus | awk {'print $2'} | sed -e 's/^"//' -e 's/",//')
		if [ "$stack_status" = 'CREATE_COMPLETE' ] || [ "$stack_status" = 'UPDATE_COMPLETE' ] || [ "$stack_status" = 'DELETE_COMPLETE' ]
		then 
			echo "$(date +"%Y-%m-%d %T") stack ${sftp_stack_name} status is ${stack_status}" 
			stack_operations_inprogress=false
			sleep 4	
		else
			if [ "$stack_status" = 'CREATE_IN_PROGRESS' ] || [ "$stack_status" = 'UPDATE_IN_PROGRESS' ] || [ "$stack_status" = 'DELETE_IN_PROGRESS' ]
			then 
				echo "$(date +"%Y-%m-%d %T") stack ${sftp_stack_name} status is ${stack_status}" 
				stack_operations_inprogress=true
				sleep 4
			else 
				echo "$(date +"%Y-%m-%d %T") Error: stack operations error or stack does not exist - exiting"
				break
			fi
		fi
	done
}


aws_cf_variables_to_ansible() 
{
		echo "$(date +"%Y-%m-%d %T") Starting stack variables export to the role"
		#___________________________________________________
		#this will take params for ansible
		SFTP_S3_BUCKET_ID=$(aws cloudformation describe-stacks --stack-name $sftp_stack_name --output text | grep S3bucketID | awk {'print $3'})
		SFTP_PUBLIC_IP=$(aws cloudformation describe-stacks --stack-name $sftp_stack_name --output text | grep PublicIPAddress | awk {'print $3'})
		SFTP_DNS=$(aws cloudformation describe-stacks --stack-name $sftp_stack_name --output text | grep DomainName | awk {'print $3'})
		echo "bucket_name: $SFTP_S3_BUCKET_ID" >> vars/main.yml
		echo "elastic_IP: $SFTP_PUBLIC_IP" >> vars/main.yml
		echo "SFTP_DNS: $SFTP_DNS" >> vars/main.yml

		#this will update known_hosts
		echo "$(date +"%Y-%m-%d %T") adding EC2 to known_hosts"
		ssh-keyscan $SFTP_DNS >> ~/.ssh/known_hosts
		ssh-keyscan $SFTP_PUBLIC_IP >> ~/.ssh/known_hosts

		#this will generate password for SFTP user <ftpuser>
		#usage: openssl passwd -salt <salt> -1 <password>
		SFTP_PASS_HASH=$(openssl passwd -salt 990 -1 $sftp_pass)
		echo "ftpuser_password: $SFTP_PASS_HASH" >> vars/main.yml
		echo "ftpuser_name: $sftp_user" >> vars/main.yml
		#___________________________________________________
}


#LIST
list_sftp_stack() 
{
	echo "$(date +"%Y-%m-%d %T") Starting stack listing"
	aws cloudformation describe-stacks --stack-name ${sftp_stack_name} --output text 
}


#DELETE
#1. remove bucket 
s3_force_removal() 
{
	echo "$(date +"%Y-%m-%d %T") Starting S3 bucket removal"
	aws s3 rb --force s3://$(grep bucket_name vars/main.yml | awk {'print $2'})
}


#2. clean known_hosts
#this helps when IP of ansible target server changes
sys_variables_cleanup() 
{
	echo "$(date +"%Y-%m-%d %T") Starting variables cleanup"
	echo "$(date +"%Y-%m-%d %T") remove sftp fqdn ($fqdn) and sftp ip ($ip) from known hosts"
	dnsrem=$(grep SFTP_DNS vars/main.yml | awk {'print $2'})
	iprem=$(grep elastic_IP vars/main.yml | awk {'print $2'})
	sed -i '/^'$dnsrem'/d' ~/.ssh/known_hosts
	sed -i '/^'$iprem'/d' ~/.ssh/known_hosts
	rm -rf vars/main.yml
}


#3. delete stack
delete_sftp_stack() 
{
	echo "$(date +"%Y-%m-%d %T") Starting stack deletion"
	aws cloudformation delete-stack --stack-name $sftp_stack_name
}


main() 
{
	if [[ $what_we_do == "-h" ]]; then
		usage
	elif [[ $what_we_do == '--list-sftp' ]]; then
		list_sftp_stack
	elif [[ $what_we_do == '--remove-sftp' ]]; then
		s3_force_removal
		sys_variables_cleanup
		delete_sftp_stack
		stack_progress
	elif [[ $what_we_do == '--create-only-stack' ]]; then
		stack_creation
		stack_progress
	elif [[ $what_we_do == '--create-sftp' ]]; then
		stack_creation
		stack_progress
		aws_cf_variables_to_ansible
		sleep 15
		ansible-playbook -i ${ansible_home}/hosts ${ansible_home}/playbooks/s3-ftp-server.yml
	else
		usage
	fi
}


main