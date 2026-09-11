# AWS Security Groups and Network Connectivity

## Purpose

This lab validates how AWS Security Groups control connectivity to the Terraform-managed EC2 instance and correlates AWS networking with the Linux guest operating system.

This work supports GitHub Issue #39:

    AWS Security Groups and Network Connectivity

Objectives:

- Understand stateful AWS Security Groups.
- Inspect inbound and outbound rules.
- Test SSH connectivity.
- Understand security boundaries.
- Relate Security Group rules to Linux ports and services.
- Document the network security architecture.

---

# Terraform-Managed EC2 Instance

AWS CLI identified the following instance:

    Name: sidiqi-devops-lab-terraform-ec2
    Instance ID: i-097b571c170748d3f
    State: running
    Private IP: 10.0.1.77
    Public IP: 34.201.4.225
    VPC: vpc-029689d7ff491f5e0
    Subnet: subnet-063ac0fce3568b5b8
    Security Group: sg-0b02a4042a30e6700
    Security Group Name: sidiqi-devops-admin-sg
    Region: us-east-1

---

# Security Group Inspection

Command:

    aws ec2 describe-security-groups \
      --region us-east-1 \
      --group-ids sg-0b02a4042a30e6700

Security Group description:

    Security group for DevOps administration host

---

# Inbound Security Group Rule

The Security Group contains the following inbound rule:

    Protocol: TCP
    Port: 22
    Source: 0.0.0.0/0
    Description: SSH administration

Security Group rule ID:

    sgr-0faedf9ea1552af34

Interpretation:

    TCP/22 is permitted from every IPv4 address.

This allows SSH traffic to reach the EC2 network interface from any IPv4 source, assuming routing and other network controls also permit the traffic.

This is functional for a lab environment but is more permissive than recommended for a production administrative interface.

---

# Outbound Security Group Rule

The outbound rule is:

    Protocol: All
    Destination: 0.0.0.0/0
    Description: Allow outbound traffic

Security Group rule ID:

    sgr-02a494c2e0b4c6197

This allows the instance to initiate outbound IPv4 connections to any destination, assuming valid routing exists.

---

# Subnet Route Table

The subnet route table contains:

    10.0.0.0/16 -> local
    0.0.0.0/0 -> igw-04644cd46bb197e7a

Both routes were active.

Interpretation:

    Traffic inside the VPC uses the local route.

    Traffic destined outside the VPC uses the Internet Gateway.

The presence of the Internet Gateway route, together with a public IPv4 address, enables public internet connectivity for the EC2 instance.

---

# AWS Security Group Architecture

The effective AWS-side network path is:

    Internet
       |
       v
    Internet Gateway
    igw-04644cd46bb197e7a
       |
       v
    Public Subnet
    10.0.1.0/24
       |
       v
    Security Group
    sg-0b02a4042a30e6700
       |
       v
    EC2 Network Interface
       |
       v
    10.0.1.77
       |
       v
    Linux Network Stack

---

# Linux Identity Validation

Connected to the Terraform-managed EC2 instance.

Commands:

    whoami
    hostname
    hostname -I

Results:

    User: ubuntu
    Hostname: ip-10-0-1-77
    IP address: 10.0.1.77

The Linux guest IP matches the private address reported by AWS.

---

# Linux Network Interface

Command:

    ip -br addr

Result:

    lo    UNKNOWN    127.0.0.1/8 ::1/128

    ens5  UP         10.0.1.77/24

The primary interface is:

    ens5

with:

    10.0.1.77/24

This confirms agreement between the AWS control plane and the Linux guest network configuration.

---

# Linux Routing

Command:

    ip route

Result:

    default via 10.0.1.1 dev ens5 proto dhcp src 10.0.1.77 metric 100

    10.0.0.2 via 10.0.1.1 dev ens5 proto dhcp src 10.0.1.77 metric 100

    10.0.1.0/24 dev ens5 proto kernel scope link src 10.0.1.77 metric 100

    10.0.1.1 dev ens5 proto dhcp scope link src 10.0.1.77 metric 100

The Linux guest uses:

    10.0.1.1

as its default gateway.

---

# SSH Service Validation

Command:

    systemctl is-active ssh

Result:

    active

The SSH service is running.

---

# SSH Socket Validation

Command:

    sudo ss -ltnp | grep ':22'

Result:

    0.0.0.0:22
    [::]:22

The SSH daemon is listening on TCP/22 on all IPv4 and IPv6 interfaces.

This is important because a Security Group rule permitting TCP/22 does not by itself guarantee that SSH will work.

The operating system must also have a service listening on TCP/22.

---

# Local SSH Connectivity Test

Command:

    nc -zv 127.0.0.1 22

Result:

    Connection to 127.0.0.1 22 port [tcp/ssh] succeeded!

This confirms that TCP/22 is reachable locally and that sshd is accepting connections.

---

# Outbound Internet Connectivity

Command:

    curl -I --max-time 10 https://example.com

Result:

    HTTP/2 200

The response confirms successful outbound HTTPS connectivity.

This correlates with:

    Security Group outbound:
    all traffic -> 0.0.0.0/0

and:

    Route table:
    0.0.0.0/0 -> Internet Gateway

---

# DNS Validation

Command:

    getent hosts example.com

Result included IPv6 addresses for example.com.

This confirms that DNS resolution is functioning from the Linux guest.

---

# Default Gateway Test

Command:

    ping -c 4 10.0.1.1

Result:

    4 packets transmitted
    4 received
    0% packet loss

Round-trip time:

    min: 0.056 ms
    avg: 0.076 ms
    max: 0.086 ms

This confirms connectivity from the guest operating system to the subnet gateway.

---

# End-to-End Connectivity Model

The SSH path is:

    Remote SSH Client
           |
           v
    Public Internet
           |
           v
    Internet Gateway
    igw-04644cd46bb197e7a
           |
           v
    AWS Route Table
           |
           v
    Security Group
    TCP/22 from 0.0.0.0/0
           |
           v
    EC2 Network Interface
    10.0.1.77
           |
           v
    Linux TCP/IP Stack
           |
           v
    sshd
    TCP/22
           |
           v
    SSH Authentication

A failure at any layer can prevent connectivity.

---

# Security Groups Are Stateful

AWS Security Groups are stateful.

This means that when inbound traffic is allowed and a connection is established, response traffic for that connection is automatically permitted.

For example:

    Client -> EC2 TCP/22

If the inbound rule allows the connection, the return packets associated with that SSH session are permitted automatically.

Administrators do not need to create a separate outbound rule specifically for the return packets of that established connection.

This behavior differs from stateless filtering models where inbound and outbound rules must be considered independently for each direction.

---

# Security Boundary

A Security Group operates at the AWS virtual network interface layer.

It does not run inside Linux.

Its role is to determine whether traffic is allowed to reach or leave the instance network interface.

The Linux operating system then independently determines whether:

- The interface is operational.
- Routing is valid.
- A host firewall permits the traffic.
- A process is listening on the destination port.
- Authentication succeeds.
- The application accepts the request.

Therefore:

    Security Group allowed

does not automatically mean:

    Application reachable

A complete troubleshooting process must validate both AWS and Linux.

---

# Security Group Versus Linux Firewall

## AWS Security Group

Operates:

    At the AWS virtual network layer.

Controls:

    Protocol
    Port
    Source
    Destination
    Security Group references
    Managed prefix lists

Characteristics:

    Stateful
    Attached to ENIs
    Managed through AWS APIs, console, CLI, or Infrastructure as Code

## Linux Firewall

Operates:

    Inside the guest operating system.

Examples:

    UFW
    nftables
    iptables
    firewalld

Controls:

    Host-level packet filtering and network policy.

These are separate security layers.

---

# Relationship Between Security Groups and Services

A useful troubleshooting model is:

    Is the Security Group allowing the port?
                 |
                 v
    Is routing available?
                 |
                 v
    Is the Linux network interface UP?
                 |
                 v
    Does Linux routing contain the expected path?
                 |
                 v
    Is a service listening on the port?
                 |
                 v
    Does host firewall policy permit the traffic?
                 |
                 v
    Does authentication succeed?

For this lab:

    Security Group TCP/22:
        allowed

    Interface ens5:
        UP

    Private IP:
        10.0.1.77

    Linux route:
        valid

    sshd:
        active

    TCP/22:
        listening

    Local TCP/22 test:
        successful

---

# Security Finding

The Terraform-managed Security Group currently allows:

    TCP/22 from 0.0.0.0/0

This means any IPv4 address can attempt to establish an SSH connection to the public interface.

Authentication is still required, but the network exposure is broader than necessary.

A least-privilege design would reduce the number of systems allowed to reach TCP/22.

Potential approaches include:

    Approved administrator CIDR
    EC2 Instance Connect managed prefix lists
    AWS Systems Manager Session Manager
    VPN access
    Bastion host access
    Private-only administration

The correct solution depends on architecture and security requirements.

---

# Infrastructure as Code Consideration

The Security Group is Terraform-managed.

Therefore the recommended remediation is not to manually edit the Security Group in the AWS console.

A manual change could introduce configuration drift between:

    Terraform configuration

and:

    Actual AWS infrastructure

The preferred workflow is:

    Identify required policy
          |
          v
    Modify Terraform
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
    Peer review
          |
          v
    terraform apply
          |
          v
    Connectivity validation

This creates an auditable and repeatable security change.

---

# Security Hardening Recommendation

The existing rule:

    TCP/22
    Source: 0.0.0.0/0

should eventually be replaced with a more restrictive administrative-access model.

This hardening should be performed through Terraform in a separate controlled task.

This Issue #39 focuses on understanding and validating the current network architecture rather than changing production-style access rules during investigation.

---

# Troubleshooting Scenario

If SSH failed, the recommended sequence would be:

    1. Verify EC2 instance state.

    2. Verify AWS status checks.

    3. Verify public/private addressing.

    4. Verify subnet route table.

    5. Verify Internet Gateway or other required network path.

    6. Verify Security Group TCP/22 rule.

    7. Verify Linux interface state.

    8. Verify Linux route table.

    9. Verify host firewall configuration.

    10. Verify sshd service state.

    11. Verify TCP/22 listening socket.

    12. Verify SSH authentication and credentials.

This approach prevents random changes and narrows the problem to the correct layer.

---

# Interview Explanation

A concise interview answer would be:

    I treat Security Groups as one layer in the end-to-end network path.

    In this lab I inspected the Terraform-managed Security Group and confirmed
    that TCP/22 was allowed from 0.0.0.0/0. I then validated the subnet route
    to the Internet Gateway and connected to the Linux guest.

    Inside Linux I verified that ens5 had the expected 10.0.1.77 address,
    the default route pointed to 10.0.1.1, sshd was active, and TCP/22 was
    listening on all interfaces.

    I also tested the SSH port locally, confirmed DNS resolution, tested
    outbound HTTPS connectivity, and validated gateway connectivity.

    That lets me separate AWS network-policy problems from Linux service or
    routing problems.

    I also identified that SSH from 0.0.0.0/0 is too permissive for a
    production design and would remediate that through Terraform rather
    than making an unmanaged console change.

---

# Leadership Perspective

For a senior engineering role, the goal is not simply to ask:

    Is port 22 open?

The larger questions are:

    Who requires access?

    From what network locations?

    Is public SSH necessary?

    Can Session Manager eliminate inbound administrative ports?

    Is the Security Group managed through Infrastructure as Code?

    How are security changes reviewed?

    How is configuration drift detected?

    What monitoring exists for administrative access?

    What is the rollback strategy?

A scalable design defines security policy centrally and applies it consistently across environments.

---

# Completion Criteria

Issue #39 required:

- Security Group inspected.
- Connectivity tested.
- Network security architecture documented.

Results:

- [x] Terraform-managed EC2 instance identified.
- [x] Security Group identified.
- [x] Inbound rules inspected.
- [x] Outbound rules inspected.
- [x] Security Group rule IDs reviewed.
- [x] Subnet routing inspected.
- [x] Internet Gateway route confirmed.
- [x] Linux identity confirmed.
- [x] Linux interface inspected.
- [x] Linux routing inspected.
- [x] SSH service validated.
- [x] TCP/22 listening socket validated.
- [x] Local SSH TCP connectivity tested.
- [x] Outbound HTTPS connectivity tested.
- [x] DNS resolution tested.
- [x] Default gateway connectivity tested.
- [x] Stateful Security Group behavior documented.
- [x] AWS versus Linux security boundaries documented.
- [x] Terraform configuration-drift considerations documented.
- [x] SSH exposure security finding documented.
- [x] Recommended future hardening documented.

---

# Conclusion

The Terraform-managed EC2 instance has functional AWS and Linux network connectivity.

The AWS Security Group:

    sg-0b02a4042a30e6700

currently allows:

    TCP/22 from 0.0.0.0/0

and permits all outbound IPv4 traffic.

The subnet route table provides:

    0.0.0.0/0 -> igw-04644cd46bb197e7a

Inside Linux:

    ens5 is UP
    10.0.1.77/24 is configured
    10.0.1.1 is the default gateway
    sshd is active
    TCP/22 is listening
    Local SSH connectivity succeeds
    DNS resolution succeeds
    HTTPS internet connectivity succeeds
    Gateway connectivity succeeds

The environment is operational, but unrestricted IPv4 SSH exposure should be hardened through Terraform using a least-privilege administrative-access design.
