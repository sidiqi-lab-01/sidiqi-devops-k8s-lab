# Terraform AWS Infrastructure Deployment

## Overview

This document describes the AWS infrastructure deployed using Terraform for the DevOps Kubernetes lab.

The Terraform configuration provides the foundational AWS networking and compute environment that will be used for Kubernetes, containerization, CI/CD, GitOps, storage, and microservices workstreams.

## AWS Region

- Region: `us-east-1`

## Network Architecture

### VPC

- Name: `sidiqi-devops-lab-vpc`
- CIDR: `10.0.0.0/16`
- DNS resolution: Enabled
- DNS hostnames: Enabled

### Public Subnets

| Name | CIDR | Availability Zone |
|---|---|---|
| `sidiqi-devops-public-1` | `10.0.1.0/24` | `us-east-1a` |
| `sidiqi-devops-public-2` | `10.0.2.0/24` | `us-east-1b` |

### Private Subnets

| Name | CIDR | Availability Zone |
|---|---|---|
| `sidiqi-devops-private-1` | `10.0.11.0/24` | `us-east-1a` |
| `sidiqi-devops-private-2` | `10.0.12.0/24` | `us-east-1b` |

## Internet Connectivity

### Internet Gateway

The VPC uses an Internet Gateway to provide Internet connectivity for resources deployed in public subnets.

- Internet Gateway: `igw-04644cd46bb197e7a`
- State: `available`

### NAT Gateway

Private subnets use a NAT Gateway for outbound Internet connectivity without assigning public IP addresses directly to private resources.

- NAT Gateway: `nat-06c1cf274e3e1d125`
- State: `available`
- Public IP: `3.221.48.15`
- Public subnet: `sidiqi-devops-public-1`

## Routing

### Public Route Table

The public route table contains:

```text
10.0.0.0/16  -> local
0.0.0.0/0    -> Internet Gateway

It is associated with both public subnets.

Private Route Table

The private route table contains:

10.0.0.0/16  -> local
0.0.0.0/0    -> NAT Gateway

It is associated with both private subnets.

Security Group

The Terraform-managed administration host uses:

Security Group: sidiqi-devops-admin-sg
Inbound: TCP/22 SSH
Outbound: All traffic

For this temporary lab, SSH is currently allowed from 0.0.0.0/0.

For production environments, SSH should be restricted to trusted CIDRs or replaced with AWS Systems Manager Session Manager.

EC2 Administration Host

Terraform manages the primary lab administration EC2 instance.

Name: sidiqi-devops-lab-terraform-ec2
Instance ID: i-097b571c170748d3f
Instance type: t3.micro
Private IP: 10.0.1.77
Public IP: 34.201.4.225
Subnet: sidiqi-devops-public-1
Terraform Files

The infrastructure is organized into separate Terraform files:

terraform/
├── providers.tf
├── variables.tf
├── vpc.tf
├── subnets.tf
├── internet-gateway.tf
├── nat.tf
├── routes.tf
├── security-groups.tf
├── ec2.tf
└── outputs.tf
File Responsibilities
File	Responsibility
providers.tf	Terraform and AWS provider configuration
variables.tf	Reusable Terraform variables
vpc.tf	VPC configuration
subnets.tf	Public and private subnets
internet-gateway.tf	Internet Gateway
nat.tf	NAT Gateway and private routing
routes.tf	Public routing
security-groups.tf	Network security rules
ec2.tf	EC2 instance
outputs.tf	Infrastructure outputs
Deployment Workflow

The Terraform deployment workflow is:

Terraform Configuration
        |
        v
terraform fmt
        |
        v
terraform validate
        |
        v
terraform plan
        |
        v
terraform apply
        |
        v
AWS Infrastructure
        |
        v
AWS CLI Validation
Terraform Commands

Format the configuration:

terraform -chdir=terraform fmt

Validate the configuration:

terraform -chdir=terraform validate

Review the proposed infrastructure changes:

terraform -chdir=terraform plan

Deploy the infrastructure:

terraform -chdir=terraform apply

Display Terraform outputs:

terraform -chdir=terraform output
Validation

The deployed infrastructure was validated using AWS CLI.

Validation included:

VPC
Public subnets
Private subnets
Internet Gateway
NAT Gateway
Route tables
EC2 instance
Security Group

Terraform validation completed successfully:

Success! The configuration is valid.

Terraform plan and apply reported:

No changes. Your infrastructure matches the configuration.
Architecture Summary
                         Internet
                            |
                     Internet Gateway
                            |
              +-------------+-------------+
              |       Public Subnets      |
              |                           |
              |      EC2 Admin Host       |
              |                           |
              |       NAT Gateway         |
              +-------------+-------------+
                            |
                     Private Routing
                            |
              +-------------+-------------+
              |       Private Subnets     |
              |                           |
              |    Future Kubernetes      |
              |      Nodes/Services       |
              +---------------------------+
Infrastructure as Code Benefits

Using Terraform provides:

Repeatable infrastructure deployments
Version-controlled infrastructure definitions
Declarative configuration
Consistent environments
Infrastructure change review through terraform plan
Reduced manual configuration
Easier disaster recovery and environment recreation
Foundation for CI/CD-driven infrastructure automation
Future Expansion

This foundation will support:

Docker containers
RKE2 Kubernetes
Helm
Argo CD
Jenkins CI/CD
Container registries
Microservices
Kubernetes storage
Multi-site Kubernetes
Air-gapped deployment simulation
DevSecOps automation
AI-assisted engineering
