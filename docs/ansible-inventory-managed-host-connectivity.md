# Ansible Inventory and Managed Host Connectivity

## Overview

This lab implements and validates Ansible connectivity from a dedicated control node to a remote Ubuntu EC2 managed node.

Two inventory models are demonstrated:

- Static inventory using `hosts.ini`
- AWS EC2 dynamic inventory using the `amazon.aws.aws_ec2` plugin

## Architecture

### Ansible Control Node

- Name: `sidiqi-devops-lab-admin`
- Region: `us-east-2`
- Private IP: `172.31.16.171`
- Role: Ansible control node

### Managed Node

- Name: `sidiqi-ansible-managed-01`
- Instance ID: `i-0cae471417bdee9a1`
- Region: `us-east-2`
- Availability Zone: `us-east-2b`
- Private IP: `172.31.22.252`
- Operating System: Ubuntu 24.04
- Instance Type: `t3.micro`
- Role tag: `ansible-managed`
- Environment tag: `lab`

## Network Design

The Ansible control node and managed node are deployed in the same AWS VPC.

Ansible connects to the managed node using its private IP address.

SSH access to the managed node is restricted by AWS Security Groups.

The managed-node security group permits TCP port 22 only from the control node security group.

This avoids exposing SSH to `0.0.0.0/0` for Ansible management traffic.

## SSH Authentication

The AWS EC2 key pair is:

`sidiqi-ansible-managed`

The public half of the control node's ED25519 SSH key was imported into AWS.

The corresponding private key remains on the Ansible control node:

`~/.ssh/id_ed25519`

The private key is protected with a passphrase.

`ssh-agent` is used to load the key for non-interactive Ansible operations.

Example:

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    ssh-add -l

Non-interactive SSH was successfully validated against the managed node.

## Static Inventory

Static inventory is stored at:

`ansible/inventory/hosts.ini`

The control node is defined locally and the managed host is mapped to its AWS private IP address.

Static inventory is useful for small, predictable, or manually managed environments.

## AWS Dynamic Inventory

Dynamic inventory is stored at:

`ansible/inventory/aws_ec2.yml`

The inventory uses:

`amazon.aws.aws_ec2`

The plugin queries AWS APIs and discovers running EC2 instances with:

`Role=ansible-managed`

The managed host is generated from its AWS `Name` tag.

The SSH destination is composed from the EC2 private IP address.

Dynamic groups are generated from AWS tags, including:

- `role_ansible_managed`
- `environment_lab`

## Authentication to AWS

The Ansible control node uses its EC2 IAM instance role to query AWS.

No static AWS access key or secret key is stored in the repository.

## Validation

### Static Inventory

Inventory graph validation showed:

    @control
      localhost

    @managed
      ansible-managed-01

The managed host successfully returned:

    ping: pong

Ansible fact gathering identified:

- Distribution: Ubuntu
- Version: 24.04
- Release: noble
- Python interpreter: `/usr/bin/python3`

Remote command execution confirmed:

    hostname -> ip-172-31-22-252
    whoami  -> ubuntu

## Dynamic Inventory Validation

AWS dynamic inventory discovered:

    sidiqi-ansible-managed-01

Dynamic inventory groups included:

    @aws_ec2
    @role_ansible_managed
    @environment_lab

The AWS dynamic inventory successfully executed:

    ansible all -m ansible.builtin.ping

Result:

    ping: pong

Remote hostname and user commands also completed successfully.

## Troubleshooting Scenario

Initial SSH validation failed with:

    Permission denied (publickey)

Network connectivity was verified first.

TCP port 22 was reachable over the private VPC network, confirming that routing and Security Group configuration were correct.

Verbose SSH diagnostics were then used:

    ssh -vvv -i ~/.ssh/id_ed25519 \
      -o IdentitiesOnly=yes \
      ubuntu@172.31.22.252

The SSH server accepted the correct public key, but the private key was protected with a passphrase.

The original non-interactive test used:

    BatchMode=yes

Batch mode prevented SSH from prompting for the private-key passphrase.

The issue was resolved by loading the private key into `ssh-agent`:

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519

After loading the key, non-interactive SSH and Ansible authentication succeeded.

## Production Relevance

This lab demonstrates several production Ansible practices:

- Separation of control and managed nodes
- Private-IP administration
- Security Group-based SSH restriction
- Passphrase-protected SSH keys
- `ssh-agent` for automation sessions
- Static inventory for predictable infrastructure
- Cloud dynamic inventory for changing environments
- AWS tag-based host discovery
- IAM role-based AWS authentication
- No static cloud credentials stored in source control
- Validation and troubleshooting of SSH before debugging Ansible

## Interview Explanation

A concise explanation:

"I configured a dedicated Ansible control node and a separate Ubuntu EC2 managed node. I restricted SSH so the managed node accepts port 22 only from the control node's AWS Security Group and used the private VPC address for management traffic. I validated static inventory first, then implemented AWS EC2 dynamic inventory using the amazon.aws plugin and IAM instance-role authentication. The dynamic inventory discovers managed instances by AWS tags and automatically creates environment and role groups. I also diagnosed a public-key authentication issue caused by a passphrase-protected SSH key and resolved it using ssh-agent without weakening key security."

## Issue #70 Completion

Completed capabilities:

- Static inventory
- Dedicated managed EC2 node
- Secure SSH connectivity
- Remote Ansible ping
- Remote fact gathering
- Remote command execution
- AWS EC2 dynamic inventory
- Tag-based dynamic groups
- IAM-role AWS API authentication
- SSH troubleshooting
- Documentation and validation evidence
