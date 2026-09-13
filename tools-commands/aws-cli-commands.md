# AWS CLI Command Reference

## AWS CLI Version

Command:

    aws --version

Usage:

Shows the installed AWS CLI version.

## Current Identity

Command:

    aws sts get-caller-identity

Usage:

Shows the AWS account, user or role, and ARN currently being used.

This is one of the first commands to run when troubleshooting AWS permissions.

## AWS Configuration

Command:

    aws configure list

Usage:

Shows the sources of AWS credentials and region configuration.

## Describe EC2 Instances

Command:

    aws ec2 describe-instances

Usage:

Displays EC2 instance information.

## Running EC2 Instances

Command:

    aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

Usage:

Lists only running EC2 instances.

## Specific Instance

Command:

    aws ec2 describe-instances --instance-ids i-0123456789abcdef0

Usage:

Displays detailed information about a specific EC2 instance.

## Start Instance

Command:

    aws ec2 start-instances --instance-ids i-0123456789abcdef0

Usage:

Starts a stopped EC2 instance.

## Stop Instance

Command:

    aws ec2 stop-instances --instance-ids i-0123456789abcdef0

Usage:

Stops a running EC2 instance.

## VPCs

Command:

    aws ec2 describe-vpcs

Usage:

Lists VPCs.

## Subnets

Command:

    aws ec2 describe-subnets

Usage:

Lists subnet configuration.

## Security Groups

Command:

    aws ec2 describe-security-groups

Usage:

Displays security groups and ingress/egress rules.

## Route Tables

Command:

    aws ec2 describe-route-tables

Usage:

Displays VPC route tables.

## Internet Gateways

Command:

    aws ec2 describe-internet-gateways

Usage:

Lists Internet Gateways.

## NAT Gateways

Command:

    aws ec2 describe-nat-gateways

Usage:

Lists NAT Gateways.

## Network Interfaces

Command:

    aws ec2 describe-network-interfaces

Usage:

Displays Elastic Network Interfaces and networking configuration.

## Availability Zones

Command:

    aws ec2 describe-availability-zones

Usage:

Lists Availability Zones available in the configured region.

## AWS Regions

Command:

    aws ec2 describe-regions --query 'Regions[].RegionName' --output table

Usage:

Lists AWS regions in table format.

## S3 Buckets

Command:

    aws s3 ls

Usage:

Lists accessible S3 buckets.

## Bucket Contents

Command:

    aws s3 ls s3://bucket-name/

Usage:

Lists objects stored in an S3 bucket.

## Upload to S3

Command:

    aws s3 cp file.txt s3://bucket-name/

Usage:

Uploads a file to S3.

## Download From S3

Command:

    aws s3 cp s3://bucket-name/file.txt .

Usage:

Downloads an object from S3.

## Sync Directory to S3

Command:

    aws s3 sync ./directory s3://bucket-name/path/

Usage:

Synchronizes local and S3 directories.

## IAM Roles

Command:

    aws iam list-roles

Usage:

Lists IAM roles when the current identity has permission.

## Local IAM Policies

Command:

    aws iam list-policies --scope Local

Usage:

Lists customer-managed IAM policies.

## Table Output

Command:

    aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table

Usage:

Uses JMESPath filtering to produce concise, readable output.

## JSON Output

Command:

    aws sts get-caller-identity --output json

Usage:

Returns AWS CLI output as structured JSON.

## Dry-Run Permission Test

Command:

    aws ec2 create-vpc --cidr-block 10.10.0.0/16 --dry-run

Usage:

Checks whether the current AWS identity is authorized without creating the VPC.

An authorized request normally returns DryRunOperation.

## CloudWatch Log Groups

Command:

    aws logs describe-log-groups

Usage:

Lists CloudWatch Logs log groups.

## EC2 Metadata Token

Command:

    TOKEN=$(curl -sS -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" http://169.254.169.254/latest/api/token)

Usage:

Obtains an IMDSv2 token from an EC2 instance.

## Current EC2 Instance ID

Command:

    curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id

Usage:

Retrieves the current EC2 instance ID using IMDSv2.

## AWS Troubleshooting Sequence

Commands:

    aws sts get-caller-identity
    aws configure list
    aws ec2 describe-instances
    aws ec2 describe-vpcs
    aws ec2 describe-subnets
    aws ec2 describe-security-groups
    aws ec2 describe-route-tables

Usage:

Provides a useful identity, compute, networking, and routing baseline when troubleshooting AWS.
