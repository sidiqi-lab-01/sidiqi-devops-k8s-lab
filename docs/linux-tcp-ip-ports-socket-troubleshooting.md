# TCP/IP, Ports and Socket Troubleshooting

## Overview

This document demonstrates TCP/IP configuration, TCP and UDP ports, socket states, process-to-port mapping, local connectivity testing, external connectivity testing, and network troubleshooting on the Ubuntu EC2 lab host.

The exercise builds on the Linux networking foundation established in Issue #34 and provides practical troubleshooting skills for AWS, Kubernetes, microservices, and production infrastructure.

## Host Networking

Observed host configuration:

* Primary interface: `ens5`
* IPv4 address: `172.31.16.171/20`
* Network: `172.31.16.0/20`
* Default gateway: `172.31.16.1`
* MTU: `9001`

Commands:

```bash
ip -4 addr
ip -4 route
```

The host uses `ens5` for IPv4 connectivity and has a default route through `172.31.16.1`.

## TCP Listening Ports

Command:

```bash
sudo ss -ltnp
```

Observed TCP listeners included:

* `0.0.0.0:22` — SSH
* `127.0.0.53:53` — systemd-resolved
* `127.0.0.54:53` — systemd-resolved
* `[::]:22` — SSH over IPv6

SSH is therefore listening on TCP port 22 for incoming connections.

## UDP Listening Ports

Command:

```bash
sudo ss -lunp
```

Observed UDP services included:

* `127.0.0.1:323` — chronyd
* `127.0.0.53:53` — systemd-resolved
* `127.0.0.54:53` — systemd-resolved
* `172.31.16.171:68` — DHCP/network management

## TCP Connection States

Command:

```bash
sudo ss -tan
```

The host had four established TCP connections.

An active SSH session was observed:

```text
172.31.16.171:22 -> 72.196.210.192:51107
```

The host also had established outbound HTTPS connections:

```text
172.31.16.171:42108 -> 3.146.13.158:443
172.31.16.171:42114 -> 3.146.13.158:443
172.31.16.171:56216 -> 3.146.8.119:443
```

These connections demonstrate normal outbound TCP communication over HTTPS.

## TCP Connection Summary

Command:

```bash
ss -s
```

Observed:

* Total sockets: 184
* TCP sockets: 8
* Established TCP connections: 4
* Closed: 0
* Orphaned: 0
* TIME_WAIT: 0

The observed TCP state indicates a healthy and relatively quiet host at the time of inspection.

## Mapping Ports to Processes

Command:

```bash
sudo lsof -i -n -P
```

Important process mappings included:

* `sshd` → TCP port 22
* `systemd-resolved` → TCP/UDP port 53
* `chronyd` → UDP port 323
* `systemd-network` → UDP port 68
* `ssm-agent` → outbound TCP port 443

This demonstrates why process-to-port mapping is important during troubleshooting. Knowing that a port is open is not sufficient; an administrator also needs to identify which process owns the socket.

## SSH Port Validation

Command:

```bash
sudo ss -ltnp 'sport = :22'
```

TCP port 22 was confirmed in the `LISTEN` state on both IPv4 and IPv6.

Local connectivity was then tested:

```bash
nc -zv 127.0.0.1 22
```

Result:

```text
Connection to 127.0.0.1 22 port [tcp/ssh] succeeded!
```

This confirms that the SSH service is reachable locally.

## DNS Port Validation

Command:

```bash
sudo ss -ltnup 'sport = :53'
```

DNS listeners were confirmed on the local system resolver addresses.

UDP connectivity was tested with:

```bash
nc -zvu 127.0.0.53 53
```

Result:

```text
Connection to 127.0.0.53 53 port [udp/domain] succeeded!
```

This confirms local UDP connectivity to the DNS resolver socket.

## External HTTPS Connectivity

Command:

```bash
nc -zv example.com 443
```

Result:

```text
Connection to example.com (172.66.147.243) 443 port [tcp/https] succeeded!
```

This confirms that the host can establish outbound TCP connectivity to an external HTTPS endpoint.

This test helps distinguish between:

* DNS resolution failure
* TCP connectivity failure
* Routing failure
* Firewall/security-group restrictions
* Application-layer problems

## Route Validation

Command:

```bash
ip route get 8.8.8.8
```

Observed route:

```text
8.8.8.8 via 172.31.16.1 dev ens5 src 172.31.16.171
```

The result confirms that traffic to the external destination is routed through the configured default gateway using `ens5`.

## TCP/IP Troubleshooting Workflow

A practical production troubleshooting workflow is:

1. Verify the interface is operational.
2. Verify the host has the expected IP address.
3. Verify the routing table.
4. Verify the destination route.
5. Check whether the expected port is listening.
6. Identify the process owning the port.
7. Inspect TCP connection states.
8. Test local connectivity.
9. Test remote connectivity.
10. Validate DNS independently.
11. Check host firewall and AWS security controls.
12. Continue with packet capture when required.

Useful commands include:

```bash
ip addr
ip route
ip route get <destination>
ss -ltnp
ss -lunp
ss -tan
ss -s
lsof -i -n -P
nc -zv <host> <port>
dig <hostname>
tcpdump
```

## TCP vs UDP

TCP is connection-oriented and provides reliable, ordered delivery.

Typical TCP applications include:

* SSH
* HTTPS
* HTTP
* Database connections

UDP is connectionless and does not provide TCP-style delivery guarantees.

Typical UDP applications include:

* DNS
* DHCP
* NTP

Understanding whether an application uses TCP or UDP is important when troubleshooting connectivity and firewall rules.

## TCP State Troubleshooting

Important TCP states include:

* `LISTEN` — application is waiting for incoming connections.
* `ESTABLISHED` — active TCP connection exists.
* `TIME_WAIT` — recently closed TCP connection is waiting before resources are fully released.
* `SYN-SENT` — connection attempt has been initiated.
* `SYN-RECV` — server has received a connection request and is responding.
* `CLOSE-WAIT` — remote side closed the connection and the local application has not fully closed its socket.

TCP states provide useful clues when diagnosing application connectivity problems.

## AWS Relationship

TCP/IP and socket troubleshooting maps directly to AWS infrastructure.

For example:

```text
Application
    ↓
TCP Port
    ↓
Linux Socket
    ↓
Linux Interface
    ↓
EC2 Network Interface
    ↓
VPC Subnet
    ↓
Route Table
    ↓
Security Group / Network ACL
    ↓
Destination
```

A connection failure can therefore originate from multiple layers.

Examples include:

* Application not listening
* Incorrect port
* Linux firewall
* Incorrect route
* AWS Security Group
* Network ACL
* DNS failure
* Remote service unavailable

## Kubernetes Relationship

The same troubleshooting principles apply to Kubernetes.

A typical path is:

```text
Client
    ↓
Load Balancer / Ingress
    ↓
Kubernetes Service
    ↓
Service Port
    ↓
Pod Target Port
    ↓
Container Application
```

Useful Kubernetes troubleshooting requires determining where the connection fails.

For example:

* Service exists but has no endpoints.
* Service port does not match target port.
* Pod application is not listening.
* NetworkPolicy blocks traffic.
* DNS cannot resolve the Service.
* Node or CNI networking has a problem.

Linux tools such as `ss`, `ip`, `nc`, `dig`, and `tcpdump` remain valuable when troubleshooting the underlying nodes.

## Production Troubleshooting Example

If an application reports that a backend service is unreachable:

### Step 1 — Check the application port

```bash
sudo ss -ltnp
```

### Step 2 — Identify the owning process

```bash
sudo lsof -i -n -P
```

### Step 3 — Test locally

```bash
nc -zv 127.0.0.1 <port>
```

### Step 4 — Check routing

```bash
ip route
ip route get <destination>
```

### Step 5 — Test remote connectivity

```bash
nc -zv <destination> <port>
```

### Step 6 — Validate DNS

```bash
dig <hostname>
```

### Step 7 — Inspect packets if necessary

```bash
sudo tcpdump -ni ens5 host <destination>
```

This approach narrows the problem systematically instead of changing multiple configuration layers at the same time.

## Key Takeaway

TCP/IP troubleshooting requires understanding the complete path from application to socket, port, interface, route, network security controls, and destination.

The lab demonstrated how to use Linux networking tools to determine:

* What ports are listening
* Which processes own those ports
* Which TCP connections are established
* Which TCP states are present
* Whether local connectivity works
* Whether external connectivity works
* How traffic is routed
* How Linux networking relates to AWS and Kubernetes

The resulting workflow provides a practical foundation for diagnosing production connectivity problems.
