# Cloud example infrastructure

Scripts for creating a typical cloud infrastructure on the major cloud providers.

The purpose of this repo is to show how to use the command-line interfaces (CLIs) of the major cloud providers to create a typical cloud infrastructure.

## Contents

- **[`aws.sh`](aws.sh):** using the [`aws`](https://aws.amazon.com/cli/) command-line tool with Amazon Web Services (AWS)
- **[`gcp.sh`](gcp.sh):** using the [`gcloud`](https://cloud.google.com/sdk/gcloud) command-line tool with Google Cloud Platfrom (GCP)

## Cloud infrastructure

The cloud infrastructure consists of the following generic components:

- A virtual private cloud (VPC) network
- A subnet (with an IP address range of 10.0.0.0/16)
- Firewall rules that allow the following types of incoming traffic:
    - All traffic from other instances in the same VPC network
    - HTTP traffic from everywhere
    - SSH traffic from your local machine
- 3 compute instances

All compute instances get a public IP address and you will be able to connect to them with SSH from your local machine.

_Below are details about the specific script for each cloud provider._

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

After all resources have been created, you can SSH to the instances with:

```bash
ssh -i aws-test-infra.pem ubuntu@PUBLIC_IP_ADDRESS
```

For more details, see the output of the `aws.sh up` command.

## Google Cloud Platform (GCP)

![GCP](assets/gcp.png)
