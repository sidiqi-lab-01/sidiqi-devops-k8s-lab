# Linux Firewall and Network Security

## Purpose

This lab examines Linux host-based firewall controls and compares them with AWS Security Groups.

The objective is to understand how network traffic is controlled at multiple layers and how Linux firewall rules interact with AWS cloud network security.

This work supports GitHub Issue #38:

    Linux Firewall and Network Security

No firewall configuration was changed during the inspection phase.

---

# Environment

Operating system:

    Ubuntu 24.04.4 LTS (Noble Numbat)

EC2 instance:

    Name: sidiqi-devops-lab-admin
    Instance ID: i-09017c52b94ad6120
    Region: us-east-2
    Private IP: 172.31.16.171

Primary interface:

    ens5

AWS Security Group:

    sg-0335b5c52add1d83e
    launch-wizard-1

---

# Firewall Layers

Network access to an EC2 Linux server can be controlled at multiple layers.

The simplified path is:

    Internet / VPC
          |
          v
    AWS Security Group
          |
          v
    EC2 Network Interface
          |
          v
    Linux Host Firewall
    UFW / nftables / iptables
          |
          v
    Listening Application
    sshd, web server, database, etc.

Security should therefore be evaluated across both the cloud platform and the operating system.

---

# Inbound Versus Outbound Traffic

Inbound traffic is traffic entering the server.

Examples:

    SSH connection to TCP/22
    HTTPS request to TCP/443
    Application request to TCP/8080

Outbound traffic is traffic initiated from the server.

Examples:

    DNS lookup
    Downloading operating-system packages
    Connecting to GitHub
    Calling an external API
    Reaching another application server

Different firewall rules can apply depending on the traffic direction.

---

# Ports and Protocols

Network firewall rules commonly evaluate:

    Source
    Destination
    Protocol
    Source port
    Destination port
    Connection state

Examples:

    TCP/22  = SSH
    TCP/80  = HTTP
    TCP/443 = HTTPS
    UDP/53  = DNS

Opening a port in a firewall does not automatically start an application.

A process must also be listening on that port.

Likewise, a service may be listening locally but still be unreachable if a firewall blocks access before the packet reaches the application.

---

# UFW Inspection

Command:

    sudo ufw status verbose

Result:

    Status: inactive

This shows that UFW is currently not enforcing firewall rules.

An important distinction was also observed through systemd.

Commands:

    systemctl is-enabled ufw
    systemctl is-active ufw

Results:

    enabled
    active

The systemd service being enabled and active does not mean that UFW filtering is enabled.

The authoritative UFW state was:

    Status: inactive

This is an important troubleshooting distinction.

---

# iptables Inspection

Command:

    sudo iptables -L -n -v

Results:

    Chain INPUT
    policy ACCEPT

    Chain FORWARD
    policy ACCEPT

    Chain OUTPUT
    policy ACCEPT

No restrictive filtering rules were present.

The default behavior was therefore to accept packets.

This means the Linux iptables layer was not preventing inbound SSH traffic.

---

# iptables NAT Inspection

Command:

    sudo iptables -t nat -L -n -v

Observed chains:

    PREROUTING
    INPUT
    OUTPUT
    POSTROUTING

All had ACCEPT policies and no NAT rules relevant to this host were configured.

No host-level NAT configuration was identified.

---

# nftables Inspection

Command:

    sudo nft list ruleset

Result:

    No rules were returned.

This indicates that no active nftables ruleset had been configured for this system.

---

# firewalld Inspection

Commands:

    systemctl is-enabled firewalld
    systemctl is-active firewalld

Results:

    not-found
    inactive

firewalld is not being used as the firewall-management framework on this Ubuntu host.

---

# Listening Ports

Command:

    sudo ss -tulpn

Important listeners included:

    TCP 0.0.0.0:22
    TCP [::]:22

    TCP 127.0.0.53:53
    TCP 127.0.0.54:53

    UDP 127.0.0.53:53
    UDP 127.0.0.54:53

    UDP 172.31.16.171:68

    UDP 127.0.0.1:323
    UDP [::1]:323

Processes included:

    sshd
    systemd-resolved
    systemd-networkd
    chronyd

---

# SSH Listening Behavior

sshd was listening on:

    0.0.0.0:22
    [::]:22

This means SSH is bound to all available IPv4 and IPv6 interfaces.

At the Linux socket layer, SSH is therefore available to receive connections.

However, whether a remote system can actually reach TCP/22 depends on upstream network controls.

In this environment, the primary upstream control is the AWS Security Group.

---

# Network Interface

Command:

    ip -br addr

Result:

    lo    UNKNOWN    127.0.0.1/8 ::1/128

    ens5  UP         172.31.16.171/20

The primary EC2 interface is:

    ens5

with private address:

    172.31.16.171/20

---

# Linux Routing

Command:

    ip route

Result:

    default via 172.31.16.1 dev ens5 proto dhcp src 172.31.16.171 metric 100

    172.31.0.2 via 172.31.16.1 dev ens5 proto dhcp src 172.31.16.171 metric 100

    172.31.16.0/20 dev ens5 proto kernel scope link src 172.31.16.171 metric 100

    172.31.16.1 dev ens5 proto dhcp scope link src 172.31.16.171 metric 100

The EC2 host uses:

    172.31.16.1

as its default gateway.

---

# AWS Security Group Identification

The EC2 Instance Metadata Service was queried using IMDSv2.

Commands:

    TOKEN=$(curl -sS -X PUT \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
      http://169.254.169.254/latest/api/token)

    INSTANCE_ID=$(curl -sS \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)

Result:

    i-09017c52b94ad6120

The security group was then retrieved with AWS CLI.

Result:

    Group ID:
    sg-0335b5c52add1d83e

    Group Name:
    launch-wizard-1

---

# AWS Security Group Inbound Rules

The inbound rule inspection identified:

    Protocol: TCP
    Port: 22

Allowed source:

    72.196.210.192/32

The /32 CIDR represents a single IPv4 address.

The same SSH rule also includes the AWS-managed EC2 Instance Connect prefix list:

    pl-03915406641cb1f53

Description:

    EC2 Instance Connect us-east-2

This allows browser-based EC2 Instance Connect traffic from the approved AWS service network.

---

# AWS Security Group Outbound Rules

The outbound rule inspection identified:

    Protocol: all
    Destination: 0.0.0.0/0

This allows the EC2 instance to initiate outbound IPv4 connections to any destination, subject to other network controls and routing.

---

# Effective SSH Security Model

The current path for an SSH connection is:

    Remote administrator
          |
          v
    AWS Security Group
          |
          | TCP/22 allowed only from
          |
          | 72.196.210.192/32
          |
          | or
          |
          | EC2 Instance Connect
          | pl-03915406641cb1f53
          |
          v
    ens5
    172.31.16.171
          |
          v
    Linux firewall layer
          |
          | UFW inactive
          | iptables ACCEPT
          | nftables no rules
          |
          v
    sshd
    TCP/22

This demonstrates defense layers but also shows that the AWS Security Group is currently performing most of the inbound SSH filtering.

---

# Linux Firewall Versus AWS Security Group

## AWS Security Group

An AWS Security Group operates at the EC2 virtual network-interface level.

It controls whether network traffic is allowed to reach or leave an EC2 instance.

Examples of security-group criteria include:

    Protocol
    Port
    Source CIDR
    Destination CIDR
    Security Group
    Managed Prefix List

In this environment, the Security Group restricts SSH before the packet reaches the Linux operating system.

## Linux Host Firewall

A Linux firewall operates inside the guest operating system.

Common technologies include:

    UFW
    nftables
    iptables
    firewalld

The Linux firewall can provide another layer of policy enforcement after traffic passes AWS networking controls.

In this environment:

    UFW is inactive.

    iptables default policies are ACCEPT.

    nftables has no configured ruleset.

Therefore no restrictive host-based firewall policy is currently being enforced.

---

# Stateful Security Concepts

AWS Security Groups are stateful.

When an allowed connection is established, return traffic for that connection is automatically permitted by the Security Group.

Linux packet filters can also perform state-aware filtering through connection-tracking functionality.

Understanding connection state is important because secure firewall design is not simply a matter of independently opening inbound and outbound ports.

---

# Defense in Depth

A stronger security architecture does not depend entirely on one control.

For example:

    Internet
       |
       v
    AWS Security Group
       |
       v
    Linux Firewall
       |
       v
    Application Authentication
       |
       v
    Authorization
       |
       v
    Logging / Monitoring

Each control provides protection if another layer is misconfigured or bypassed.

---

# Important Finding

The server currently depends primarily on the AWS Security Group for SSH network filtering.

This is not automatically an error.

Cloud workloads frequently use Security Groups as an important network-policy layer.

However, the security posture should be intentional and documented.

If host-based firewall enforcement is required by system policy, compliance requirements, classified-environment standards, or defense-in-depth design, a Linux firewall policy should also be configured and managed.

---

# Safe Change Management

Firewall modifications can disconnect administrators from remote systems.

For that reason, no UFW, iptables, or nftables rules were changed during this inspection.

Before enabling a host firewall remotely, administrators should verify that management access will remain permitted.

For example, an SSH allow rule should be established before enabling a default-deny inbound policy.

A safer workflow is:

    1. Identify required services.
    2. Identify required management sources.
    3. Add explicit allow rules.
    4. Verify rules.
    5. Enable the firewall.
    6. Test from a separate session.
    7. Maintain rollback access.

This avoids accidentally locking administrators out of the server.

---

# Troubleshooting Model

When a remote service cannot be reached, troubleshoot from the outside inward.

    Is the EC2 instance running?
            |
            v
    Is AWS routing correct?
            |
            v
    Does the Security Group allow traffic?
            |
            v
    Is the Linux interface UP?
            |
            v
    Does the Linux firewall allow traffic?
            |
            v
    Is the application listening?
            |
            v
    Is application authentication working?

For SSH specifically:

    EC2 running
       |
       v
    route available
       |
       v
    Security Group permits TCP/22
       |
       v
    Linux firewall permits packet
       |
       v
    sshd listens on TCP/22
       |
       v
    SSH authentication succeeds

This layered approach helps isolate the actual failure domain.

---

# Key Commands

Inspect UFW:

    sudo ufw status verbose

Inspect iptables:

    sudo iptables -L -n -v

Inspect NAT rules:

    sudo iptables -t nat -L -n -v

Inspect nftables:

    sudo nft list ruleset

Inspect firewall services:

    systemctl is-enabled ufw
    systemctl is-active ufw

    systemctl is-enabled firewalld
    systemctl is-active firewalld

Inspect listening ports:

    sudo ss -tulpn

Inspect interfaces:

    ip -br addr

Inspect routes:

    ip route

Inspect EC2 Security Groups:

    aws ec2 describe-instances

    aws ec2 describe-security-groups

---

# Interview Explanation

A concise interview explanation would be:

    I troubleshoot network security in layers.

    I first determine whether the cloud network layer permits traffic.
    In AWS that includes the route table, Security Group, and potentially
    other VPC controls.

    Then I inspect the Linux host itself using tools such as ip, ss,
    ufw, nftables, and iptables.

    In this lab I found that UFW was inactive, iptables had ACCEPT default
    policies, and nftables had no active rules. SSH was listening on port
    22 on all interfaces.

    The actual inbound SSH restriction was therefore being enforced by
    the AWS Security Group, which allowed TCP/22 only from one administrator
    address and the regional EC2 Instance Connect managed prefix list.

    That demonstrates why I validate both cloud controls and operating-system
    controls rather than assuming one layer represents the entire security
    posture.

---

# Leadership Perspective

For a production environment, the technical question is not simply:

    Should UFW be enabled?

The stronger engineering question is:

    What security policy are we trying to enforce, at which layer,
    who owns that policy, and how is it maintained consistently?

A senior engineering approach would define:

    Required network flows

    Approved administrative paths

    Least-privilege rules

    Infrastructure-as-Code ownership

    Host configuration standards

    Logging and monitoring requirements

    Change-control and rollback procedures

    Compliance requirements

This prevents individual servers from accumulating inconsistent firewall configurations.

---

# Completion Criteria

Issue #38 required:

- Firewall configuration inspected.
- Rules understood.
- Linux firewall versus AWS Security Group documented.

Results:

- [x] UFW configuration inspected.
- [x] iptables rules inspected.
- [x] iptables NAT table inspected.
- [x] nftables ruleset inspected.
- [x] firewalld status inspected.
- [x] Listening services inspected.
- [x] Network interfaces inspected.
- [x] Linux routing inspected.
- [x] AWS Security Group identified.
- [x] AWS inbound rules inspected.
- [x] AWS outbound rules inspected.
- [x] Inbound and outbound traffic concepts documented.
- [x] Ports and protocols documented.
- [x] Linux firewall versus AWS Security Group documented.
- [x] Layered troubleshooting model documented.
- [x] No unsafe firewall changes made during inspection.

---

# Conclusion

The Linux administration instance is currently not enforcing restrictive host-based firewall rules.

UFW reports:

    inactive

iptables uses:

    ACCEPT

for INPUT, FORWARD, and OUTPUT policies.

nftables contains no active rules.

SSH listens on:

    0.0.0.0:22
    [::]:22

The primary inbound SSH restriction is therefore provided by AWS Security Group:

    sg-0335b5c52add1d83e

which permits TCP/22 from:

    72.196.210.192/32

and:

    pl-03915406641cb1f53

for EC2 Instance Connect in us-east-2.

This lab demonstrates the relationship between cloud network security controls and Linux host-level firewall controls and reinforces the importance of layered network troubleshooting and defense-in-depth design.
