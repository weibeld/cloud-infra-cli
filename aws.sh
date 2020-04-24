#!/bin/bash
#
# This script creates (and deletes) the following resources:
#
#   1 VPC (1 route table, 1 security group, 1 network ACL)
#   1 internet gateway
#   1 subnet
#   1 route table
#   2 security groups
#   1 key pair
#   3 EC2 instances
#   3 EBS volumes
#   3 elastic network interfaces (ENI)
#   ----------------------------------
#   Total: 19 resources
#   ==================================
#
#------------------------------------------------------------------------------#

set -e

# Tag to attach to created resources for identifying the resources to delete in
# the 'down' step. This tag should not be already used by any other resources.
# Also, there shouldn't be a key pair with the same name as the tag value.
tag_key=project
tag_value=aws-test-infra

# Set output format to 'text' to facilitate capturing resource IDs.
export AWS_DEFAULT_OUTPUT=text 

# Prevent use of a pager (such as 'less') for output that exceeds screen height.
export AWS_PAGER=""

up() {
  # Create VPC (implicitly creates a default route table, security group, and network ACL)
  vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId)

  # Create internet gateway and attach it to the VPC
  internet_gateway_id=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId)
  aws ec2 attach-internet-gateway --internet-gateway-id "$internet_gateway_id" --vpc-id "$vpc_id"

  # Create subnet
  subnet_id=$(aws ec2 create-subnet --cidr-block 10.0.0.0/16 --vpc-id "$vpc_id" --query Subnet.SubnetId)

  # Create route table, add a route, and associate it with the subnet
  route_table_id=$(aws ec2 create-route-table --vpc-id "$vpc_id" --query RouteTable.RouteTableId --output text)
  aws ec2 create-route --route-table-id "$route_table_id" --destination-cidr-block 0.0.0.0/0 --gateway-id "$internet_gateway_id" 
  aws ec2 associate-route-table --route-table-id "$route_table_id" --subnet-id "$subnet_id"

  # Create security group 1 (allowing all incoming internal traffic)
  security_group_1_id=$(aws ec2 create-security-group --group-name internal-all --vpc-id "$vpc_id" --description "Allow all incoming traffic from the same security group")
  aws ec2 authorize-security-group-ingress --group-id "$security_group_1_id" --protocol all --source-group "$security_group_1_id"

  # Create security group 2 (allowing incoming HTTP and SSH traffic)
  security_group_2_id=$(aws ec2 create-security-group --group-name external-http-and-ssh --vpc-id "$vpc_id" --description "Allow incoming traffic to port 80 (from everywhere) and port 22 (from specific IP address)")
  aws ec2 authorize-security-group-ingress --group-id "$security_group_2_id" --protocol tcp --port 80 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id "$security_group_2_id" --protocol tcp --port 22 --cidr "$(curl -s checkip.amazonaws.com)/32"

  # Get ID of Ubuntu 18.04 AMI (AMI ID is different for each region)
  ami_id=$(aws ec2 describe-images --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200408" --query 'Images[0].ImageId')

  # Create key pair
  aws ec2 create-key-pair --key-name "$tag_value" --query KeyMaterial >"$tag_value".pem
  chmod 400 "$tag_value".pem

  # Create instances (implicitly creates a network interface and volume for each instance)
  aws ec2 run-instances \
    --count 3 \
    --image-id "$ami_id" \
    --instance-type t2.medium  \
    --key-name "$tag_value" \
    --subnet-id "$subnet_id" \
    --security-group-ids "$security_group_1_id" "$security_group_2_id" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=$tag_key,Value=$tag_value}]"

  # Add tag to all created resources
  aws ec2 create-tags \
    --resources "$vpc_id" "$internet_gateway_id" "$subnet_id" "$route_table_id" "$security_group_1_id" "$security_group_2_id" \
    --tags "Key=$tag_key,Value=$tag_value"

  cat <<EOF

✅ Done!

You can query the IDs and public IP addresses of the created EC2 instances with:

  aws ec2 describe-instances \\
    --filters "Name=tag:$tag_key,Values=$tag_value" \\
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \\
    --output text

You can log in to an instance through SSH with:

  ssh -i $tag_value.pem ubuntu@<PUBLIC-IP-ADDRESS>

The absolute path of '$tag_value.pem' on your local machine is:

  $(pwd)/$tag_value.pem

EOF

}

down() {
  # Tag filter for identifying resources to delete
  filter="Name=tag:$tag_key,Values=$tag_value"
  
  # Delete instances
  instance_ids=($(aws ec2 describe-instances --filters "$filter" --query 'Reservations[*].Instances[*].InstanceId'))
  aws ec2 terminate-instances --instance-ids "${instance_ids[@]}"

  # Wait until all instances are in the 'terminated' state
  while true; do
    instance_states=($(aws ec2 describe-instances --filters "$filter" --query 'Reservations[*].Instances[*].State.Name'))
    for s in "${instance_states[@]}"; do
      if [[ "$s" != terminated ]]; then
        continue 2
      fi
    done
    break
  done
  
  # Delete security groups (associated with instances)
  security_group_ids=($(aws ec2 describe-security-groups --filters "$filter" --query 'SecurityGroups[*].GroupId'))
  for s in "${security_group_ids[@]}"; do
    aws ec2 delete-security-group --group-id "$s"
  done
  
  # Delete route table (associated with subnet)
  route_table_id=$(aws ec2 describe-route-tables --filters "$filter" --query 'RouteTables[0].RouteTableId')
  route_table_association_id=$(aws ec2 describe-route-tables --filters "$filter" --query 'RouteTables[0].Associations[0].RouteTableAssociationId')
  aws ec2 disassociate-route-table --association-id "$route_table_association_id"
  aws ec2 delete-route-table  --route-table-id "$route_table_id"

  # Delete subnet
  subnet_id=$(aws ec2 describe-subnets --filters "$filter" --query 'Subnets[0].SubnetId')
  aws ec2 delete-subnet --subnet-id "$subnet_id"

  # Delete internet gateway (attached to VPC)
  vpc_id=$(aws ec2 describe-vpcs --filters "$filter" --query 'Vpcs[0].VpcId')
  internet_gateway_id=$(aws ec2 describe-internet-gateways --filters "$filter" --query 'InternetGateways[0].InternetGatewayId')
  aws ec2 detach-internet-gateway --internet-gateway-id "$internet_gateway_id" --vpc-id "$vpc_id"
  aws ec2 delete-internet-gateway --internet-gateway-id "$internet_gateway_id"

  # Delete VPC
  aws ec2 delete-vpc --vpc-id "$vpc_id"

  # Delete key pair
  aws ec2 delete-key-pair --key-name "$tag_value"
  rm -f $(pwd)/$tag_value.pem

  cat <<EOF

✅ Done!

All resources have been deleted.

Note that the instances will still exist for about an hour in the 'terminated'
state before they will be definitely deleted.

You can query the state of all your instances with:

  aws ec2 describe-instances \\
    --filters "$filter" \\
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \\
    --output text

EOF
}

usage() {
  echo "USAGE:"
  echo "  $(basename $0) up|down"
}

case "$1" in
  up) up ;;
  down) down ;;
  *) usage && exit 1 ;;
esac
