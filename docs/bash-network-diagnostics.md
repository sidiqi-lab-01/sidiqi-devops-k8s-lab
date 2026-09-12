# Bash Network Diagnostics Script

## Issue

GitHub Issue #42 - Bash Network Diagnostics Script

## Objective

Create a reusable Bash script that automatically collects Linux network diagnostic information and performs common connectivity tests.

The script demonstrates:

- Bash scripting
- Linux networking
- troubleshooting automation
- structured diagnostics
- application-port testing
- reusable operational tooling

## Script

The diagnostic tool is located at:

    scripts/network-diagnostics.sh

The script is read-only.

It does not modify:

- network interfaces
- IP addresses
- route tables
- DNS configuration
- Linux firewall rules
- AWS Security Groups
- VLAN configuration

## Usage

Run diagnostics against the local host:

    ./scripts/network-diagnostics.sh

Run diagnostics with an additional target:

    ./scripts/network-diagnostics.sh 172.31.22.252

The optional target may be an IP address or hostname.

## Diagnostics Collected

The script collects and tests:

1. Timestamp
2. Hostname
3. Current user
4. Kernel version
5. CPU architecture
6. Operating system
7. Network interfaces
8. Interface link state
9. IPv4 addresses
10. IPv6 addresses
11. IPv4 routing table
12. IPv6 routing table
13. Default route
14. Default gateway
15. DNS configuration
16. systemd-resolved configuration
17. DNS resolution
18. Listening TCP and UDP ports
19. Socket statistics
20. Public IP reachability
21. TCP/443 connectivity
22. HTTPS connectivity
23. ARP / neighbor table
24. Interface statistics
25. Optional target DNS lookup
26. Optional target ICMP connectivity
27. Optional target TCP/22 connectivity

## Result Classification

The script uses three result classifications:

    [PASS]
    [WARN]
    [FAIL]

PASS indicates a successful diagnostic check.

WARN indicates a condition that requires interpretation but does not necessarily mean networking is broken.

FAIL indicates a fundamental local network problem.

The script also generates a final summary:

    PASS checks
    WARN checks
    FAIL checks

and one of the following overall states:

    HEALTHY
    COMPLETED WITH WARNINGS
    ATTENTION REQUIRED

## Lab Environment

The script was tested on the DevOps lab administration EC2 instance.

Observed host information:

    Hostname: ip-172-31-16-171
    OS: Ubuntu 24.04.4 LTS
    Kernel: 6.17.0-1017-aws
    Architecture: x86_64

Primary AWS interface:

    ens5
    172.31.16.171/20

Default gateway:

    172.31.16.1

AWS DNS server:

    172.31.0.2

The host also contained the existing Linux VLAN lab interfaces:

    vlp0
    vlp0.100
    veth1-br
    veth2-br
    br-vlan

The diagnostics script detected these interfaces without changing them.

## Local Host Test

Command:

    ./scripts/network-diagnostics.sh

Observed summary:

    PASS checks : 9
    WARN checks : 0
    FAIL checks : 0

    OVERALL STATUS: HEALTHY

The local host successfully validated:

- operating system information
- active network interfaces
- IPv4 addressing
- default IPv4 route
- default gateway connectivity
- DNS resolution
- public IP connectivity
- TCP/443 connectivity
- HTTPS connectivity

## Routing Validation

The script detected the following relevant routes:

    default via 172.31.16.1 dev ens5
    172.31.0.2 via 172.31.16.1 dev ens5
    172.31.16.0/20 dev ens5
    192.168.100.0/24 dev vlp0.100

This confirmed that the AWS management network and Linux VLAN lab remained separate.

## DNS Validation

The system used the local systemd-resolved stub:

    127.0.0.53

The active upstream DNS service for ens5 was:

    172.31.0.2

Search domain:

    us-east-2.compute.internal

DNS resolution for example.com succeeded.

## Listening Socket Validation

The script identified SSH listening on:

    0.0.0.0:22
    [::]:22

It also identified the local DNS resolver sockets on TCP/UDP port 53.

## Internet Connectivity Validation

The following tests succeeded:

    ICMP -> 1.1.1.1
    TCP/443 -> example.com
    HTTPS -> https://example.com

The HTTPS endpoint returned:

    HTTP 200

## Managed Node Connectivity Test

The script was tested against the Ansible managed EC2 instance:

    172.31.22.252

Command:

    ./scripts/network-diagnostics.sh 172.31.22.252

Observed target results:

    [PASS] Target can be resolved or interpreted: 172.31.22.252
    [WARN] ICMP connectivity failed to 172.31.22.252
    [PASS] TCP/22 reachable on 172.31.22.252

Summary:

    PASS checks : 11
    WARN checks : 1
    FAIL checks : 0

    OVERALL STATUS: COMPLETED WITH WARNINGS

## Important Troubleshooting Lesson

The Ansible managed host did not respond to ICMP ping, but TCP port 22 was reachable.

This demonstrates that:

    ping failure != host failure

ICMP may be filtered while the required application protocol remains available.

For SSH and Ansible troubleshooting, TCP/22 is a more relevant connectivity test than ICMP alone.

This is why the script classifies failed ICMP target tests as WARN rather than FAIL.

## Network Interface Statistics

The primary AWS interface showed:

    RX errors: 0
    RX dropped: 0
    TX errors: 0
    TX dropped: 0

This provided an additional indicator that the primary EC2 network interface was operating normally.

## Controlled Failure Testing

A deliberately non-production test destination can be supplied to demonstrate warning behavior:

    ./scripts/network-diagnostics.sh 203.0.113.1

The TEST-NET address is used to exercise negative connectivity paths without changing the host network configuration.

Expected target behavior includes warnings for unavailable ICMP and TCP/22 connectivity.

## Exit Codes

Current behavior:

    0 = diagnostics completed successfully or with warnings
    2 = one or more fundamental FAIL checks detected

Warnings do not automatically create a non-zero exit code because filtered ICMP and similar conditions may be normal in production environments.

## Bash Design

The script uses reusable functions including:

    separator
    section
    pass
    warn
    fail
    command_exists
    run_command

Counters track:

    PASS_COUNT
    WARN_COUNT
    FAIL_COUNT

This produces consistent structured output and avoids repeating formatting and status logic throughout the script.

## Safety

The script performs diagnostic operations only.

It does not run configuration-changing commands such as:

    ip addr add
    ip route add
    ip link set
    resolvectl dns
    ufw
    iptables
    nft
    aws ec2 authorize-security-group-ingress

This makes the script suitable for routine troubleshooting without altering the system being diagnosed.

## Real-World Operational Use

This type of script can be used during incidents to quickly answer questions such as:

- Does the host have an IP address?
- Is the primary interface up?
- Is there a default route?
- What gateway is configured?
- Which DNS server is being used?
- Does DNS resolution work?
- Can the host reach the internet?
- Is HTTPS available?
- Which services are listening?
- Are interface errors occurring?
- Is a remote server reachable?
- Is the required application port reachable even if ping fails?

Automating these checks reduces repetitive manual troubleshooting and creates consistent diagnostic output.

## Interview Explanation

A concise interview explanation is:

"I created a reusable Bash network diagnostics script for my Linux and AWS lab. Instead of manually running individual commands during every troubleshooting session, the script collects host information, interfaces, IP addresses, routing, DNS configuration, listening sockets, neighbor information and interface counters. It then performs DNS, ICMP, TCP and HTTPS connectivity tests and classifies the results as PASS, WARN or FAIL. I tested it against an actual Ansible managed EC2 node and found a good real-world example where ICMP failed but TCP port 22 succeeded. That demonstrated why I test the service port instead of assuming a failed ping means the server is unavailable. The script is read-only, reusable and version-controlled through Git."

## Issue #42 Completion Criteria

- [x] Script created under scripts/
- [x] Script tested
- [x] Output reviewed
- [x] Documentation added
- [ ] Git commit completed
- [ ] Git push completed

