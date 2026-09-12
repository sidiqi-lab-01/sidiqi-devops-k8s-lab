# Network Troubleshooting Toolkit

## Purpose

This document defines a repeatable Linux network troubleshooting methodology for the Sidiqi DevOps / Kubernetes Infrastructure Lab.

The workflow uses standard Linux networking tools to isolate connectivity failures systematically instead of relying on a single command such as ping.

Issue #41 requires practical use of:

- ip
- ss
- ping
- curl
- dig
- nslookup
- traceroute
- tcpdump

The toolkit also integrates the existing reusable automation:

    scripts/network-diagnostics.sh

## Lab Environment

Control node:

- Hostname: ip-172-31-16-171
- Operating system: Ubuntu 24.04.4 LTS
- Primary interface: ens5
- Primary IPv4 address: 172.31.16.171/20
- Default gateway: 172.31.16.1
- AWS DNS server: 172.31.0.2
- Region: us-east-2

Ansible managed node:

- Name: sidiqi-ansible-managed-01
- Private IP: 172.31.22.252
- SSH port: TCP/22

Additional Linux VLAN lab interfaces are also present, including:

- vlp0
- vlp0.100
- br-vlan
- veth1-br
- veth2-br

The AWS management interface ens5 is not modified by this troubleshooting workflow.

---

# Troubleshooting Methodology

The troubleshooting process follows the network stack from local configuration toward the remote application.

## Step 1 - Verify Interface State and IP Addressing

Start by confirming that the expected interface exists, is UP, and has the correct address.

Commands:

    ip -brief address
    ip address show dev ens5
    ip -brief link

Observed primary interface:

    ens5 UP 172.31.16.171/20

Questions answered:

- Is the interface present?
- Is the interface UP?
- Does it have the expected IP address?
- Is the subnet correct?
- Are unexpected interfaces or addresses present?

If the interface is DOWN or the IP address is missing, troubleshoot the local host before testing remote connectivity.

---

## Step 2 - Verify Routing

Inspect the routing table.

Commands:

    ip route show
    ip route get 1.1.1.1
    ip route get 172.31.22.252

Observed default route:

    default via 172.31.16.1 dev ens5

Observed route to the Internet test target:

    1.1.1.1 via 172.31.16.1 dev ens5 src 172.31.16.171

Observed route to the Ansible managed node:

    172.31.22.252 dev ens5 src 172.31.16.171

Interpretation:

- Public traffic uses the default gateway.
- The Ansible managed host is reachable directly through ens5 because it is inside the connected VPC network.

Questions answered:

- Is a default route configured?
- Which gateway will traffic use?
- Which interface will carry the traffic?
- Which source IP will Linux select?
- Is the destination directly connected or routed?

---

## Step 3 - Test Basic ICMP Reachability

Use ping as an initial reachability test, but do not treat ping failure as proof that a service is unavailable.

Commands:

    ping -c 3 172.31.16.1
    ping -c 3 1.1.1.1
    ping -c 3 172.31.22.252

Results:

Default gateway:

    3 packets transmitted, 3 received, 0% packet loss

Public target:

    3 packets transmitted, 3 received, 0% packet loss

Ansible managed node:

    3 packets transmitted, 0 received, 100% packet loss

Important lesson:

The managed node did not respond to ICMP, but later TCP and packet-capture tests proved that SSH was healthy.

Therefore:

    Failed ping != failed host or failed application

ICMP may be blocked or filtered independently of the application protocol.

---

## Step 4 - Validate DNS

Use both dig and nslookup.

Commands:

    dig example.com
    dig +short example.com
    nslookup example.com

The system resolver used the local systemd-resolved stub:

    127.0.0.53

The underlying AWS DNS server was:

    172.31.0.2

Direct AWS DNS query:

    dig @172.31.0.2 example.com

Observed result:

    status: NOERROR

Example A records returned:

    104.20.23.154
    172.66.147.243

Observed query time:

    1 msec

Direct nslookup test:

    nslookup example.com 172.31.0.2

This confirmed that both the local resolver path and direct AWS DNS resolution were operational.

Questions answered:

- Can the hostname resolve?
- Which DNS server answered?
- Is the problem DNS or network connectivity?
- Does querying the upstream resolver directly work?

---

## Step 5 - Identify Listening Services

Use ss to inspect sockets and listening ports.

Commands:

    ss -tuln
    ss -ltn
    ss -s

Observed services included:

    TCP 0.0.0.0:22
    TCP [::]:22
    TCP/UDP 127.0.0.53:53

Interpretation:

- SSH is listening locally on TCP/22.
- systemd-resolved is listening locally for DNS.

Questions answered:

- Is the application listening?
- Is it listening on the expected port?
- Is it bound to localhost only?
- Is it listening on IPv4, IPv6, or both?

A remote connectivity problem cannot be fixed at the network layer if the application itself is not listening.

---

## Step 6 - Test the Required Service Port

Test the protocol that actually matters.

For the Ansible managed node, SSH TCP/22 is the required service.

Command:

    timeout 5 bash -c 'cat < /dev/null > /dev/tcp/172.31.22.252/22'

Observed result:

    [PASS] TCP/22 reachable on 172.31.22.252

This result is especially important because ICMP to the same server failed.

Conclusion:

- Route is valid.
- Target host is reachable for SSH.
- TCP/22 is open and responding.
- ICMP failure does not indicate an SSH failure.

---

## Step 7 - Validate the Application Layer

Use curl for HTTP and HTTPS testing.

Command:

    curl -I --max-time 5 https://example.com

Observed result:

    HTTP/2 200

Detailed timing test produced approximately:

    HTTP status: 200
    DNS lookup: 0.000716s
    TCP connect: 0.002323s
    TLS/application ready: 0.035271s
    Total time: 0.042257s

curl can therefore help distinguish latency occurring during:

- DNS resolution
- TCP connection establishment
- TLS negotiation
- Application response

This is useful when troubleshooting latency rather than complete connection failure.

---

## Step 8 - Analyze the Network Path

Use traceroute to identify the network path.

Standard test:

    traceroute -n -m 8 -w 1 1.1.1.1

The destination was reached in five hops.

TCP-based test:

    sudo traceroute -T -p 443 -n -m 8 -w 1 1.1.1.1

The HTTPS-oriented TCP traceroute also reached the destination in five hops.

Using different traceroute methods is useful because some networks filter traditional traceroute traffic while permitting real application protocols.

Questions answered:

- How far does traffic travel?
- At which hop does a failure begin?
- Does TCP traceroute behave differently from the default method?
- Is a path issue occurring before or after the cloud network boundary?

---

## Step 9 - Capture Packets with tcpdump

tcpdump provides packet-level evidence and is useful when higher-level commands give incomplete or conflicting results.

### DNS Packet Capture

Initial test using the normal resolver:

    sudo tcpdump -ni ens5 'port 53'

A normal dig query produced no packets on ens5 because the local systemd-resolved stub or cache could answer the request without generating new upstream traffic.

To force upstream DNS traffic, query AWS DNS directly.

Capture:

    sudo tcpdump -ni ens5 'host 172.31.0.2 and port 53'

Generate traffic:

    dig @172.31.0.2 example.com A

Observed packet flow:

    172.31.16.171 -> 172.31.0.2:53 DNS query
    172.31.0.2:53 -> 172.31.16.171 DNS response

Capture statistics:

    2 packets captured
    2 packets received by filter
    0 packets dropped by kernel

This proves both outbound DNS traffic and the inbound DNS response traversed ens5.

### SSH Packet Capture

Capture:

    sudo tcpdump -ni ens5 'host 172.31.22.252 and tcp port 22'

Generate connection:

    timeout 3 bash -c 'cat < /dev/null > /dev/tcp/172.31.22.252/22'

Observed flow included:

    SYN
    SYN-ACK
    ACK

The remote system also returned:

    SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.19

Interpretation:

This is packet-level proof that:

- packets left the control node
- the managed node received them
- the managed node responded
- TCP completed its three-way handshake
- the SSH application answered

This provided stronger evidence than ping alone.

---

# Failure Scenario 1 - Ping Fails but SSH Works

Target:

    172.31.22.252

Observed ICMP result:

    100% packet loss

Observed TCP/22 result:

    PASS

Observed packet capture:

    SYN -> SYN-ACK -> ACK

Observed application banner:

    SSH-2.0-OpenSSH_9.6p1

Diagnosis:

The host and SSH service are healthy. ICMP is unavailable or filtered.

Lesson:

Never conclude that a host is down based only on ping.

Test the protocol and port required by the application.

---

# Failure Scenario 2 - Unreachable TCP Port

A controlled negative test used the documentation TEST-NET address:

    203.0.113.1

Test:

    timeout 5 bash -c 'cat < /dev/null > /dev/tcp/203.0.113.1/22'

Observed result:

    TCP/22 not reachable

This demonstrates how the toolkit distinguishes an actual service connectivity failure from an ICMP-only failure.

---

# Failure Scenario 3 - DNS Capture Initially Shows No Traffic

Initial tcpdump filter:

    port 53

A normal:

    dig example.com

produced no packets on ens5.

This did not mean DNS or tcpdump was broken.

The host uses:

    systemd-resolved
    127.0.0.53

The query could be answered through the local resolver or cache.

The test was refined by forcing a direct upstream DNS query:

    dig @172.31.0.2 example.com

tcpdump then captured both the DNS request and response.

Lesson:

Troubleshooting commands must be interpreted in context. A zero-packet capture can itself provide useful information about where traffic is being handled.

---

# Automated Diagnostics

Issue #42 created a reusable script:

    scripts/network-diagnostics.sh

Usage:

    ./scripts/network-diagnostics.sh

Target-specific usage:

    ./scripts/network-diagnostics.sh 172.31.22.252

Observed managed-node result:

    PASS checks : 11
    WARN checks : 1
    FAIL checks : 0

    OVERALL STATUS: COMPLETED WITH WARNINGS

The warning was the failed ICMP test while TCP/22 succeeded.

The script automates collection of:

- operating system information
- interfaces
- IP addresses
- routes
- DNS configuration
- listening sockets
- gateway connectivity
- public connectivity
- TCP connectivity
- HTTP/HTTPS connectivity
- neighbor information
- interface counters
- target-specific connectivity

Manual commands remain important for deeper investigation, while the script provides rapid baseline collection.

---

# Recommended Troubleshooting Sequence

Use this sequence during incidents.

## 1. Local interface

    ip -brief link
    ip -brief address

Confirm interface state and addressing.

## 2. Routing

    ip route
    ip route get TARGET

Confirm route, gateway, interface, and source address.

## 3. Gateway

    ping GATEWAY

Confirm local network reachability.

## 4. External IP

    ping 1.1.1.1

If this works while DNS names fail, investigate DNS.

## 5. DNS

    dig HOSTNAME
    nslookup HOSTNAME

If required:

    dig @DNS_SERVER HOSTNAME

## 6. Listening service

For local services:

    ss -tuln

Confirm the service is actually listening.

## 7. Target service port

Test the real application port instead of relying solely on ping.

Examples:

    TCP/22   SSH
    TCP/80   HTTP
    TCP/443  HTTPS

## 8. Application test

For HTTP/HTTPS:

    curl -I https://HOST

Use curl timing data when investigating latency.

## 9. Network path

    traceroute TARGET

If required:

    traceroute -T -p PORT TARGET

## 10. Packet capture

    tcpdump -ni INTERFACE FILTER

Use packet captures to confirm whether requests leave the host and whether responses return.

---

# Troubleshooting Decision Flow

A practical decision process is:

    Interface DOWN
        |
        +-- Fix local interface or operating system configuration

    Interface UP
        |
        v
    Correct IP?
        |
        +-- No -> Fix addressing
        |
        v
    Valid route?
        |
        +-- No -> Fix routing
        |
        v
    Gateway reachable?
        |
        +-- No -> Investigate subnet, route, local firewall, VPC networking
        |
        v
    Destination name resolves?
        |
        +-- No -> Investigate DNS
        |
        v
    Required service port reachable?
        |
        +-- No -> Investigate service, firewall, Security Group, NACL, routing
        |
        v
    Application responds correctly?
        |
        +-- No -> Investigate application/service layer
        |
        v
    Capture packets if evidence remains unclear

---

# Cloud Troubleshooting Considerations

In AWS, Linux troubleshooting must be combined with cloud-side networking checks.

Relevant components include:

- EC2 instance state
- ENI configuration
- VPC
- subnet
- route table
- Internet Gateway or NAT Gateway
- Security Groups
- Network ACLs
- EC2 Instance Connect rules
- private versus public addressing

A Linux host may be configured correctly while AWS networking blocks the traffic.

Likewise, AWS networking may be correct while the Linux service is not listening.

Troubleshooting should therefore verify both layers.

---

# Safety

The commands used in this toolkit are primarily read-only diagnostics.

The workflow does not modify:

- ens5 configuration
- IP addresses
- routes
- DNS configuration
- AWS Security Groups
- Network ACLs
- firewall rules
- VLAN configuration

Packet capture requires elevated privileges but does not modify network configuration.

---

# Interview Explanation

A concise interview response:

"I use a layered troubleshooting approach instead of starting with assumptions. I first verify the interface and addressing with ip, then inspect the route and source address. I test the gateway and basic reachability, validate DNS with dig or nslookup, inspect listening services with ss, and then test the actual application port. For HTTP services I use curl to separate DNS, TCP, TLS, and application latency. I use traceroute to inspect the network path and tcpdump when I need packet-level proof.

In my AWS lab I had a good example where ping to an Ansible managed EC2 instance failed, but TCP port 22 succeeded. I captured the connection with tcpdump and saw the SYN, SYN-ACK, ACK, and the OpenSSH banner. That proved the server and SSH service were healthy and that the failed ping was only an ICMP issue. I also built a reusable Bash diagnostics script to automate the baseline checks."

---

# Issue #41 Completion Evidence

Required tools tested:

- [x] ip
- [x] ss
- [x] ping
- [x] curl
- [x] dig
- [x] nslookup
- [x] traceroute
- [x] tcpdump

Objectives:

- [x] Diagnose DNS problems
- [x] Diagnose routing problems
- [x] Diagnose port connectivity
- [x] Identify listening services
- [x] Capture packets
- [x] Build structured troubleshooting workflow

Completion criteria:

- [x] Each required tool tested
- [x] Troubleshooting workflow documented
- [x] Example failure scenarios analyzed
