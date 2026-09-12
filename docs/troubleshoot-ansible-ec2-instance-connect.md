# Troubleshoot EC2 Instance Connect Access to Ansible Managed Node

## Overview

This troubleshooting exercise diagnosed an AWS EC2 instance that was fully reachable using SSH and Ansible but could not initially be accessed through AWS Console EC2 Instance Connect.

The investigation used a layered troubleshooting methodology covering AWS infrastructure, networking, SSH, Ansible, and EC2 Instance Connect.

## Environment

### Ansible Control Node

- Name: `sidiqi-devops-lab-admin`
- Instance ID: `i-09017c52b94ad6120`
- Private IP: `172.31.16.171`
- Security Group: `sg-0335b5c52add1d83e`
- Region: `us-east-2`

### Ansible Managed Node

- Name: `sidiqi-ansible-managed-01`
- Instance ID: `i-0cae471417bdee9a1`
- Private IP: `172.31.22.252`
- Public IP: `18.117.197.17`
- Instance Type: `t3.micro`
- Availability Zone: `us-east-2b`
- VPC: `vpc-0bf46c95fae75905c`
- Subnet: `subnet-016e3b4b6433a4130`
- Security Group: `sg-0fd43c51dcffe0cc7`
- Key Pair: `sidiqi-ansible-managed`
- OS: Ubuntu 24.04

## Problem

Direct SSH from the Ansible control node worked.

Static Ansible inventory worked.

AWS EC2 dynamic inventory worked.

However, browser access using AWS Console EC2 Instance Connect failed.

## Instance Health Validation

Commands:

    aws ec2 describe-instances \
      --region us-east-2 \
      --instance-ids i-0cae471417bdee9a1

    aws ec2 describe-instance-status \
      --region us-east-2 \
      --instance-ids i-0cae471417bdee9a1 \
      --include-all-instances

Results:

    Instance state: running
    Instance status: ok
    System status: ok

## Network Interface Validation

Command:

    aws ec2 describe-network-interfaces \
      --region us-east-2 \
      --filters \
        Name=attachment.instance-id,Values=i-0cae471417bdee9a1

Results:

    ENI: eni-0cf0cb2b931708d6f
    Status: in-use
    Private IP: 172.31.22.252
    Public IP: 18.117.197.17

## Security Group Validation

Managed-node Security Group:

    sg-0fd43c51dcffe0cc7

Original SSH rule:

    TCP/22
    Source: sg-0335b5c52add1d83e

This permitted SSH from the Ansible control-node Security Group.

It did not permit AWS EC2 Instance Connect.

## Routing Validation

VPC main route table contained:

    172.31.0.0/16 -> local
    0.0.0.0/0 -> Internet Gateway

Routing was healthy.

## Network ACL Validation

The subnet Network ACL permitted the required inbound and outbound traffic.

The NACL was not responsible for the connection failure.

## Port 22 Validation

From the Ansible control node:

    timeout 5 bash -c \
      'cat < /dev/null > /dev/tcp/172.31.22.252/22'

Result:

    [PASS] TCP/22 reachable

## SSH Authentication Validation

The passphrase-protected ED25519 key was loaded:

    ssh-add ~/.ssh/id_ed25519

Direct SSH test:

    ssh \
      -o BatchMode=yes \
      -o IdentitiesOnly=yes \
      -i ~/.ssh/id_ed25519 \
      ubuntu@172.31.22.252 \
      'hostname; whoami; hostname -I'

Result:

    ip-172-31-22-252
    ubuntu
    172.31.22.252

SSH was healthy.

## Static Ansible Validation

Command:

    ansible managed \
      -m ansible.builtin.ping

Result:

    ansible-managed-01 | SUCCESS
    ping: pong

## AWS Dynamic Inventory Validation

Command:

    ansible \
      -i inventory/aws_ec2.yml \
      all \
      -m ansible.builtin.ping

Result:

    sidiqi-ansible-managed-01 | SUCCESS
    ping: pong

This proved the problem was not Ansible.

## EC2 Instance Connect Prefix List

Command:

    aws ec2 describe-managed-prefix-lists \
      --region us-east-2 \
      --filters \
        Name=prefix-list-name,Values=com.amazonaws.us-east-2.ec2-instance-connect

Result:

    pl-03915406641cb1f53

## EC2 Instance Connect Package

Command:

    ssh ubuntu@172.31.22.252 \
      'dpkg -l | grep ec2-instance-connect'

Result:

    ec2-instance-connect 1.1.17-0ubuntu1

The required package was installed.

## Root Cause

The managed-node Security Group permitted port 22 only from the Ansible control-node Security Group.

Therefore:

    Control node -> managed node = allowed

but:

    AWS EC2 Instance Connect -> managed node = not allowed

## Resolution

Added the AWS-managed EC2 Instance Connect prefix list to the managed-node Security Group.

Command:

    aws ec2 authorize-security-group-ingress \
      --region us-east-2 \
      --group-id sg-0fd43c51dcffe0cc7 \
      --ip-permissions '[
        {
          "IpProtocol": "tcp",
          "FromPort": 22,
          "ToPort": 22,
          "PrefixListIds": [
            {
              "PrefixListId": "pl-03915406641cb1f53",
              "Description": "AWS EC2 Instance Connect"
            }
          ]
        }
      ]'

## Final Security Model

The managed host now accepts SSH from:

    sg-0335b5c52add1d83e

for Ansible control-node access.

It also accepts SSH from:

    pl-03915406641cb1f53

for AWS EC2 Instance Connect.

SSH remains closed to:

    0.0.0.0/0

## Final Architecture

    Ansible Control Node
    SG sg-0335b5c52add1d83e
            |
            | TCP/22
            v
    sidiqi-ansible-managed-01
    SG sg-0fd43c51dcffe0cc7
            ^
            | TCP/22
            |
    AWS EC2 Instance Connect
    pl-03915406641cb1f53

## Troubleshooting Approach

The troubleshooting process followed this sequence:

1. Instance state
2. AWS health checks
3. ENI
4. Security Group
5. Route table
6. Network ACL
7. TCP/22
8. SSH authentication
9. Static Ansible inventory
10. Dynamic AWS inventory
11. EC2 Instance Connect prefix list
12. EC2 Instance Connect package
13. Root-cause isolation
14. Least-privilege remediation
15. Final validation

## Result

AWS Console EC2 Instance Connect succeeded after adding the AWS-managed prefix list.

Existing Ansible and SSH connectivity remained operational.

The solution preserved least-privilege access without exposing SSH to the public internet.
