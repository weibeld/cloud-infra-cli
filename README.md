# Cloud example infrastructure

Scripts for creating a typical cloud infrastructure on the major cloud providers.

The purpose of this repo is to show how to use the command-line interfaces (CLIs) of the major cloud providers to create a typical cloud infrastructure.

## Contents

- **[`aws.sh`](aws.sh):** using the [`aws`](https://aws.amazon.com/cli/) command-line tool with Amazon Web Services (AWS)
- **[`gcp.sh`](gcp.sh):** using the [`gcloud`](https://cloud.google.com/sdk/gcloud) command-line tool with Google Cloud Platfrom (GCP)

## Cloud infrastructure

The cloud infrastructure consists of the following generic components:

- A virtual private cloud (VPC) network
- A subnet (with a private IP address range of 10.0.0.0/16)
- Firewall rules that allow the following types of incoming traffic:
    - All traffic from other instances of the example infrastructure
    - HTTP traffic from everywhere
    - SSH traffic from your local machine
- 3 compute instances (running Ubuntu 18.04)

All compute instances get a public IP address and you will be able to connect to them with SSH from your local machine.

_The concrete resources that are created for each cloud provider are listed below._

## Prerequisites

To use the provided scripts, you must have an installed and fully configured command-line interface of the relevant cloud provider:

- [`aws`](https://aws.amazon.com/cli/) for AWS ([installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- [`gcloud`](https://cloud.google.com/sdk/gcloud) for GCP ([installation instructions](https://cloud.google.com/sdk/gcloud#downloading_the_gcloud_command-line_tool))

The configuration must include the credentials to access your account as well as a default region.

## Amazon Web Services (AWS)

![AWS](assets/aws.png)

### Usage

Create the infrastructure:

```bash
./aws.sh up
```
Delete the infrastructure:

```bash
./aws.sh down
```
### Resources

The [`aws.sh`](aws.sh) script creates (and deletes) the following AWS resources:

- 1 [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) (1 route table, 1 security group, 1 [network ACL](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html))
- 1 [internet gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
- 1 [subnet](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
- 1 [route table](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html)
- 2 [security groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- 1 [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- 3 [EC2 instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html) (3 [EBS volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html), 3 [network interfaces](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html))

### Notes

After all resources have been created, you can list the IDs and public IP addresses of the created instances with:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:project,Values=aws-example-infra" \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
  --output text
```

The `aws.sh up` command creates a private key file named `aws-example-infra.pem` in your current working directory. You can use this file to SSH to the instances as follows:

```bash
ssh -i aws-example-infra.pem ubuntu@PUBLIC_IP_ADDRESS
```

## Google Cloud Platform (GCP)

![GCP](assets/gcp.png)

### Usage

Create the infrastructure:

```bash
./gcp.sh up
```
Delete the infrastructure:

```bash
./gcp.sh down
```

### Resources

The [`gcp.sh`](gcp.sh) script creates (and deletes) the following GCP resources:

- 1 [VPC network](https://cloud.google.com/vpc/docs/vpc)
- 1 [subnet](https://cloud.google.com/vpc/docs/vpc#vpc_networks_and_subnets)
- 3 [firewall rules](https://cloud.google.com/vpc/docs/firewalls)
- 3 [VM instances](https://cloud.google.com/compute/docs/instances)

### Notes

After all resources have been created, you can list the created instances, including their private and public IP addresses, with:

```bash
gcloud compute instances list --filter 'tags.items=gcp-example-infra'
```

You can SSH to the instances with:

```bash
# As the default user
gcloud compute ssh INSTANCE_NAME
# As root
gcloud compute ssh root@INSTANCE_NAME
```

You can also connect to the instances with a standalone SSH client as follows:

```bash
ssh -i ~/.ssh/google_compute_engine PUBLIC_IP_ADDRESS
```
