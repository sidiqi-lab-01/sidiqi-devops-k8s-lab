# Linux Networking Interfaces and IP Addressing

## Overview

This document demonstrates Linux network interface inspection, IP addressing, routing, DNS configuration, socket inspection, and basic network troubleshooting on the Ubuntu EC2 lab host.

The work supports the Linux & Networking milestone and establishes the networking foundation needed for AWS, Kubernetes, container networking, firewall, DNS, routing, and infrastructure troubleshooting exercises.

## Host Baseline

Observed host:

- Hostname: `ip-172-31-16-171`
- FQDN: `ip-172-31-16-171.us-east-2.compute.internal`
- Primary interface: `ens5`
- Interface alternate name: `enp0s5`
- Private IPv4 address: `172.31.16.171/20`
- Network: `172.31.16.0/20`
- Broadcast address: `172.31.31.255`
- Default gateway: `172.31.16.1`
- MTU: `9001`
- Network configuration: `systemd-networkd`
- DNS resolver: `systemd-resolved`

The hostname and DNS search domain indicate that this EC2 host is operating in an AWS environment associated with `us-east-2`.

## Network Interface Inspection

### List interfaces and IP addresses

```bash
ip addr

The primary network interface is ens5.

Observed IPv4 configuration:

inet 172.31.16.171/20

The loopback interface lo provides:

127.0.0.1/8
::1/128
Inspect interface state
ip link

The ens5 interface is operational:

BROADCAST,MULTICAST,UP,LOWER_UP
state UP

This indicates that the interface is administratively enabled and has an active lower-layer link.

Concise network overview
ip -br addr

Observed:

lo      UNKNOWN  127.0.0.1/8 ::1/128
ens5    UP       172.31.16.171/20

This is useful during incident response because it provides a quick summary of interface state and assigned addresses.

IPv4 Addressing

The primary IPv4 address is:

172.31.16.171/20

A /20 prefix provides the network:

172.31.16.0/20

The observed broadcast address is:

172.31.31.255

The address is dynamically configured, as shown by the DHCP-related route and address lifetime.

Command used:

ip -4 addr show dev ens5
Interface Statistics

Command:

ip -s link show dev ens5

Observed statistics:

RX:
bytes     864486673
packets   871713
errors    0
dropped   0
missed    0
mcast     0

TX:
bytes     30979883
packets   243940
errors    0
dropped   0
carrier   0
collsns   0

The absence of RX/TX errors and drops indicates no interface-level packet error condition was observed during this inspection.

MTU

Command:

ip link show dev ens5

Observed:

mtu 9001

An MTU of 9001 is commonly used for jumbo-frame networking in AWS environments.

MTU is important when troubleshooting fragmentation, packet loss, VPN connectivity, overlay networks, and Kubernetes networking.

Routing Table

Command:

ip -4 route

Observed routes:

default via 172.31.16.1 dev ens5
172.31.0.2 via 172.31.16.1 dev ens5
172.31.16.0/20 dev ens5
172.31.16.1 dev ens5

The default route is:

default via 172.31.16.1 dev ens5

This means traffic destined for networks without a more specific route is sent through gateway 172.31.16.1.

The connected subnet is:

172.31.16.0/20 dev ens5

The route to the DNS server is:

172.31.0.2 via 172.31.16.1
Route Selection Testing
Internet destination

Command:

ip route get 8.8.8.8

Observed:

8.8.8.8 via 172.31.16.1 dev ens5 src 172.31.16.171

This confirms that traffic toward the public destination is routed through the default gateway.

AWS metadata destination

Command:

ip route get 169.254.169.254

Observed:

169.254.169.254 via 172.31.16.1 dev ens5 src 172.31.16.171

The command demonstrates how Linux selects the route for the AWS metadata service address.

Neighbor / ARP Table

Command:

ip neigh

Observed:

172.31.16.1 dev ens5 lladdr 06:36:fc:a2:6f:b3 REACHABLE

The gateway is currently reachable at Layer 2 from the Linux host.

Neighbor-table inspection is useful for diagnosing local connectivity, gateway reachability, and ARP-related issues.

DNS Configuration

The system uses systemd-resolved.

Command:

resolvectl status

Observed DNS configuration:

Current DNS Server: 172.31.0.2
DNS Servers: 172.31.0.2
DNS Domain: us-east-2.compute.internal

The /etc/resolv.conf file points local applications to the systemd-resolved stub:

nameserver 127.0.0.53

The file is dynamically managed and should not be manually edited.

DNS Testing
dig

Command:

dig example.com

The lookup completed successfully with:

status: NOERROR

The query was handled by:

127.0.0.53

The resolver returned IPv4 addresses for example.com.

nslookup

Command:

nslookup example.com

The lookup also completed successfully through:

127.0.0.53

Using both dig and nslookup provides practical DNS troubleshooting coverage.

Local Hostname Resolution

Command:

getent hosts "$(hostname)"

The hostname resolved to the host's local IPv6 link-local address:

fe80::4bd:49ff:feba:9ed5 ip-172-31-16-171

getent is useful because it tests name resolution through the system's configured NSS resolution mechanisms.

Listening Network Services

Command:

sudo ss -ltnp

Observed TCP listeners included:

0.0.0.0:22
[::]:22
127.0.0.54:53
127.0.0.53:53

TCP port 22 is used by SSH.

DNS stub listeners are provided by systemd-resolved.

UDP inspection:

sudo ss -lunp

Observed services included:

127.0.0.1:323
127.0.0.54:53
127.0.0.53:53
172.31.16.171:68

Port 323 is associated with chronyd.

UDP port 68 is used by the DHCP client.

Socket Summary

Command:

ss -s

Observed:

TCP:
6 total
2 established

UDP:
5 total

The host had two established TCP connections at the time of inspection.

Network Services

The host confirmed both networking services are active:

systemctl is-active systemd-networkd
systemctl is-active systemd-resolved

Observed:

active
active

systemd-networkd manages network configuration while systemd-resolved provides local DNS resolution.

Networking Tools

The following tools were available:

/usr/sbin/ifconfig
/usr/bin/netstat
/usr/bin/ss
/usr/sbin/ip
/usr/bin/dig
/usr/bin/nslookup
/usr/sbin/traceroute

The preferred modern Linux tools for most troubleshooting are ip and ss, while ifconfig and netstat remain useful for compatibility and familiarity.

Linux Networking and AWS

The Linux networking configuration maps directly to AWS networking concepts.

Linux:

ens5
172.31.16.171/20
172.31.16.1

AWS concepts:

EC2 network interface
Private IPv4 address
VPC subnet
VPC routing
Security groups
Network ACLs
Internet/NAT gateway routing

Linux determines how packets leave the operating system using its local routing table. AWS then applies VPC routing and network security controls outside the instance.

A successful Linux route does not automatically mean that traffic will be allowed by AWS. Security groups, network ACLs, route tables, gateways, and destination services must also permit the traffic.

Linux Networking and Kubernetes

These concepts directly support Kubernetes troubleshooting.

Linux networking provides the foundation for:

Node IP addresses
Pod networking
Service networking
Container interfaces
CNI plugins
Routing
DNS
Network policies
Load balancing
Ingress
Network troubleshooting

Common Kubernetes troubleshooting commands build on the same Linux concepts:

ip addr
ip route
ip link
ss -ltnp
ss -lunp
dig
nslookup
traceroute

Understanding the node's Linux networking configuration is therefore essential when diagnosing Kubernetes connectivity problems.

Production Troubleshooting Workflow

A practical Linux network troubleshooting sequence is:

ip -br addr
ip link
ip route
ip route get <destination>
ip neigh
resolvectl status
dig <hostname>
ss -ltnp
ss -lunp

The workflow moves from:

Interface
    ↓
IP address
    ↓
Route
    ↓
Gateway / neighbor
    ↓
DNS
    ↓
Listening service

This helps isolate whether a problem is related to the local interface, addressing, routing, DNS, or application service.

Example Troubleshooting Scenarios
No network connectivity

Check:

ip link
ip -br addr
ip route
ip neigh

Look for:

Interface down
Missing IP address
Missing default route
Unreachable gateway
DNS failure

Check:

resolvectl status
dig example.com
nslookup example.com

Determine whether the problem is:

Local resolver
DNS server
Search domain
Network connectivity
External DNS resolution
Application connection failure

Check:

ss -ltnp
ss -lunp

Confirm:

Application is listening
Correct protocol is used
Correct port is configured
Service is bound to the expected address
Routing problem

Check:

ip route
ip route get <destination>

This determines which interface and gateway Linux will use.

Key Commands Demonstrated
ip addr
ip link
ip -br addr
ip route
ip route get 8.8.8.8
ip route get 169.254.169.254
ip neigh
resolvectl status
dig example.com
nslookup example.com
getent hosts "$(hostname)"
ss -s
sudo ss -ltnp
sudo ss -lunp
systemctl is-active systemd-networkd
systemctl is-active systemd-resolved
Completion Checklist
 Linux network interfaces inspected
 IPv4 addressing documented
 Interface state verified
 Interface statistics inspected
 MTU documented
 Routing table inspected
 Route selection tested
 Gateway/neighbor table inspected
 DNS configuration documented
 DNS resolution tested
 Listening TCP/UDP sockets inspected
 Network services verified
 AWS networking relationship documented
 Kubernetes networking relationship documented
 Network troubleshooting workflow documented
Key Takeaway

Linux networking troubleshooting starts with the fundamentals: identify the interface, verify the IP address, inspect the routing table, verify gateway reachability, test DNS, and inspect listening sockets.

These same fundamentals apply when troubleshooting EC2 instances, AWS VPC connectivity, Kubernetes nodes, container networking, microservices, and production infrastructure.
