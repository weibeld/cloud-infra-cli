#!/bin/bash

# Tag to attach to the created resources (should be unique)
tag_key=purpose
tag_value=aws-test-infra

# Text output format facilitate capturing of IDs of created resources
export AWS_DEFAULT_OUTPUT=text

# TODO: check if it's necessary to disable pager. The AWS CLI uses a pager by default if the output is longer than the terminal window.
#export AWS_PAGER=

up() {


  # Create VPC (creates default route table, security group, and network ACL)
  vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId)

  # Create subnet
  subnet_id=$(aws ec2 create-subnet --cidr-block 10.10.0.0/16 --vpc-id "$vpc_id" --query Subnet.SubnetId)

  # Get AMI ID of Ubuntu 18.04 AMI (AMI ID is different for each region)
  ami_id=$(aws ec2 describe-images --filter "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200408" --query 'Images[0].ImageId')

  # Create key pair
  aws ec2 create-key-pair --key-name k8s --query KeyMaterial >~/.ssh/aws-k8s.pem

  # Get ID of default security group of VPC
  default_security_group_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId')

  # Create custom security group
  security_group_id=$(aws ec2 create-security-group --group-name allow-http-and-ssh --description "Allow incoming traffic to port 80 (from everywhere) and port 22 (from specific IP address)" --vpc-id "$vpc_id")
  aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 80 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 22 --cidr "$(curl checkip.amazonaws.com)/32"

  # Create internet gateway and attach it to the VPC
  internet_gateway_id=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId)
  aws ec2 attach-internet-gateway --internet-gateway-id "$internet_gateway_id" --vpc-id "$vpc_id"

  # Create route table, add route to internet gateway, and associate with subnet
  route_table_id=$(aws ec2 create-route-table --vpc-id "$vpc_id" --query RouteTable.RouteTableId --output text)
  aws ec2 create-route --route-table-id "$route_table_id" --destination-cidr-block 0.0.0.0/0 --gateway-id "$internet_gateway_id" 
  aws ec2 associate-route-table --route-table-id "$route_table_id" --subnet-id "$subnet_id"

  # TODO: investigate if it's worth to use elastic IP addresses instead of normal public IP addresses
  #       => It's not worth it. The elastic IP addresses are from similar ranges as the automatically assigned IP addresses and the instances get no public DNS name either

  # Create 3 instances
  aws ec2 run-instances \
    --count 3 \
    --image-id "$ami_id" \
    --instance-type t2.medium  \
    --key-name k8s \
    --subnet-id "$subnet_id" \
    --security-group-ids "$default_security_group_id" "$security_group_id" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=$tag_key,Value=$tag_value}]"

  cat <<EOF

You can query the IDs and public IP addresses of the created EC2 instances with:

aws ec2 describe-instances \
  --filters "Name=tag:$tag_key,Values=$tag_value" \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
  --output text
EOF

}

down() {
  # Delete instances
  instance_ids=($(aws ec2 describe-instances --filters "Name=tag:$tag_key,Values=$tag_value" --query 'Reservations[*].Instances[*].InstanceId'))
  aws ec2 terminate-instances --instance-ids "${instance_ids[@]}"


}

