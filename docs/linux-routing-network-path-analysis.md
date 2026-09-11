# Linux Routing and Network Path Analysis

## Overview

This lab documents Linux routing tables, default gateways, route selection, and network path analysis on an Ubuntu EC2 instance.

The objective is to understand how Linux determines where packets should be sent and how Linux routing relates to AWS VPC and Kubernetes networking.

## Environment

- Operating system: Ubuntu Linux
- Primary interface: `ens5`
- Private IPv4 address: `172.31.16.171/20`
- Default gateway: `172.31.16.1`
- AWS DNS resolver route: `172.31.0.2`
- Feature branch: `feature/linux-routing-network-path-analysis`

## Routing Table

Command used:

`ip route`

Observed routing table:

    default via 172.31.16.1 dev ens5 proto dhcp src 172.31.16.171 metric 100
    172.31.0.2 via 172.31.16.1 dev ens5 proto dhcp src 172.31.16.171 metric 100
    172.31.16.0/20 dev ens5 proto kernel scope link src 172.31.16.171 metric 100
    172.31.16.1 dev ens5 proto dhcp scope link src 172.31.16.171 metric 100

## Routing Table Interpretation

### Default Route

The default route is:

    default via 172.31.16.1 dev ens5

This means traffic that does not match a more specific route is forwarded through gateway `172.31.16.1` using interface `ens5`.

The preferred source address is `172.31.16.171`.

### Local Subnet Route

The directly connected subnet route is:

    172.31.16.0/20 dev ens5 proto kernel scope link src 172.31.16.171 metric 100

This means destinations within `172.31.16.0/20` are directly reachable through `ens5`.

Linux does not need to use the default route for hosts located on the same connected subnet.

### AWS DNS Resolver Route

The host also contains:

    172.31.0.2 via 172.31.16.1 dev ens5 proto dhcp src 172.31.16.171 metric 100

This route provides access to the AWS-provided DNS resolver used by the EC2 environment.

## Route Selection

Command used:

`ip route get 8.8.8.8`

Result:

    8.8.8.8 via 172.31.16.1 dev ens5 src 172.31.16.171 uid 1001
        cache

Linux selected:

- Destination: `8.8.8.8`
- Gateway: `172.31.16.1`
- Interface: `ens5`
- Source IP: `172.31.16.171`

Because `8.8.8.8` does not match a more specific local route, Linux uses the default route.

## Interface Validation

Command used:

`ip -br addr`

Observed:

    lo    UNKNOWN    127.0.0.1/8 ::1/128
    ens5  UP         172.31.16.171/20

The primary EC2 interface `ens5` is UP and has the expected private address.

## Default Gateway Validation

The default gateway was identified dynamically using:

    DEFAULT_GW=$(ip route | awk '/default/ {print $3; exit}')
    echo "$DEFAULT_GW"

Result:

    172.31.16.1

Connectivity was tested using:

`ping -c 4 172.31.16.1`

Result:

- Packets transmitted: 4
- Packets received: 4
- Packet loss: 0%
- Average latency: approximately 0.072 ms

This confirms successful communication between the Linux host and its default gateway.

## External IP Connectivity

External connectivity was tested with:

`ping -c 4 8.8.8.8`

Result:

- Packets transmitted: 4
- Packets received: 4
- Packet loss: 0%
- Average latency: approximately 7.761 ms

This confirms that traffic can successfully leave the local network and reach an external Internet destination.

## DNS and Routing Validation

DNS resolution and network connectivity were tested together with:

`ping -c 4 example.com`

The hostname resolved to:

    172.66.147.243

Results:

- Packets transmitted: 4
- Packets received: 4
- Packet loss: 0%
- Average latency: approximately 1.173 ms

This demonstrates that both DNS resolution and IP routing are functioning correctly.

## Network Path Analysis to 8.8.8.8

Command used:

`traceroute 8.8.8.8`

The destination was successfully reached in six hops.

Observed path:

    1  242.5.18.131 / 242.5.19.135
    2  240.1.248.9
    3  151.148.13.59 / 151.148.13.61 / 151.148.13.55
    4  142.251.226.65 / 142.251.77.147 / 192.178.249.227
    5  142.251.60.207 / 142.251.60.215 / 142.251.60.203
    6  dns.google (8.8.8.8)

This demonstrates that traffic left the EC2 environment, traversed upstream network infrastructure, and successfully reached Google DNS.

Multiple addresses on some traceroute hops can occur because network paths may use load-balanced infrastructure.

## Network Path Analysis to example.com

Command used:

`traceroute example.com`

The destination resolved to `172.66.147.243`.

Observed path:

    1  242.8.173.129 / 242.8.173.131 / 242.8.172.135
    2  240.3.104.1
    3  151.148.11.249
    4  172.68.168.15
    5  172.66.147.243

The destination was successfully reached in five hops.

The final path included Cloudflare network infrastructure before reaching the destination.

## How Linux Selects Routes

Linux generally prefers the most specific matching route.

For example, the route:

    172.31.16.0/20

is more specific than the default route.

Traffic destined for the directly connected subnet therefore uses the local route.

Traffic destined for an external address such as `8.8.8.8` does not match that subnet and therefore uses:

    default via 172.31.16.1

This behavior is commonly referred to as longest-prefix matching.

## Routing Troubleshooting Workflow

### 1. Verify the Interface

Run:

`ip -br addr`

Confirm that:

- the expected interface is UP
- the expected IP address is configured
- the subnet mask is correct

### 2. Inspect the Routing Table

Run:

`ip route`

Verify:

- directly connected networks
- default gateway
- interface selection
- source address
- route metrics

### 3. Inspect Route Selection

Run:

`ip route get 8.8.8.8`

This identifies exactly how Linux intends to reach the destination.

### 4. Test the Default Gateway

Run:

`ping -c 4 172.31.16.1`

If this fails, investigate:

- network interface configuration
- subnet configuration
- host networking
- cloud networking
- firewall policies

### 5. Test an External IP Address

Run:

`ping -c 4 8.8.8.8`

If the gateway works but the external IP fails, investigate:

- AWS route tables
- Internet Gateway
- NAT Gateway
- network ACLs
- security groups
- host firewall
- upstream routing

### 6. Test DNS-Based Connectivity

Run:

`ping -c 4 example.com`

If an IP destination works but a hostname does not, investigate DNS separately.

### 7. Analyze the Network Path

Run:

    traceroute 8.8.8.8
    traceroute example.com

Traceroute helps identify where packets stop progressing or where latency increases.

## Unreachable Network Troubleshooting

When a destination cannot be reached, troubleshoot from the local host outward.

Recommended sequence:

1. Check interface state.
2. Check the host IP address.
3. Inspect the Linux routing table.
4. Check the selected route with `ip route get`.
5. Test the local gateway.
6. Test an external IP.
7. Test DNS resolution.
8. Run traceroute.
9. Review host firewall configuration.
10. Review AWS security groups.
11. Review AWS network ACLs.
12. Review the subnet route table.
13. Verify NAT Gateway or Internet Gateway configuration.
14. Verify return-path routing.

This approach helps isolate whether the problem exists on the Linux host, inside AWS networking, or beyond the VPC.

## Linux and AWS Routing Relationship

Linux routing and AWS VPC routing work together but operate at different layers.

The EC2 operating system first uses its local Linux routing table.

For external traffic, this host selects:

    Linux application
          |
          v
    Linux routing table
          |
          v
    ens5
          |
          v
    Default gateway 172.31.16.1
          |
          v
    AWS VPC networking
          |
          v
    Subnet route table
          |
          v
    Internet Gateway / NAT Gateway / other target
          |
          v
    Destination network

AWS subnet route tables can direct traffic toward targets such as:

- Internet Gateway
- NAT Gateway
- Transit Gateway
- VPC peering connection
- VPN gateway
- network interface
- other VPC networking targets

The Linux host therefore needs a valid local route while AWS also needs a valid VPC-level route.

## AWS Troubleshooting Example

Suppose an EC2 instance cannot reach the Internet.

First inspect Linux:

    ip -br addr
    ip route
    ip route get 8.8.8.8
    ping -c 4 172.31.16.1

If the Linux configuration appears correct, inspect AWS:

- subnet route table
- Internet Gateway or NAT Gateway
- security group
- network ACL
- subnet design
- return-path routing

This prevents incorrectly assuming every connectivity problem is caused by the operating system.

## Kubernetes Relevance

The same routing principles apply to Kubernetes environments.

Kubernetes networking requires connectivity between:

- Pods
- Nodes
- Services
- ingress components
- external networks

Linux networking commands remain useful when troubleshooting Kubernetes nodes:

    ip addr
    ip route
    ip route get <destination>
    ping <destination>
    traceroute <destination>

Kubernetes networking may additionally involve:

- CNI plugins
- Pod CIDRs
- Service CIDRs
- kube-proxy
- network policies
- overlay networks
- AWS VPC CNI
- node routing
- cloud route tables

A Kubernetes connectivity issue may therefore require examining both Linux host routing and cluster networking.

## Production Troubleshooting Scenario

Assume an application running on a Linux host cannot connect to an external service.

A structured troubleshooting approach is:

1. Verify that `ens5` is UP.
2. Confirm that `172.31.16.171/20` is configured.
3. Inspect `ip route`.
4. Confirm the default gateway.
5. Run `ip route get <destination>`.
6. Ping the gateway.
7. Test an external IP.
8. Verify DNS resolution.
9. Run traceroute.
10. Inspect Linux firewall configuration.
11. Inspect AWS security groups.
12. Inspect network ACLs.
13. Inspect AWS route tables.
14. Verify the Internet Gateway or NAT Gateway.
15. Confirm the return network path.

This method separates host-level, cloud-level, and external-network problems.

## Commands Used

The following commands were used during this lab:

    ip route
    ip route get 8.8.8.8
    ip -br addr
    ping -c 4 172.31.16.1
    ping -c 4 8.8.8.8
    ping -c 4 example.com
    traceroute 8.8.8.8
    traceroute example.com

## Validation Summary

The lab successfully validated:

- Linux routing table inspection
- local subnet routing
- default gateway identification
- route selection
- longest-prefix matching concepts
- network interface configuration
- gateway reachability
- external Internet reachability
- DNS-based connectivity
- traceroute network path analysis
- Linux and AWS VPC routing relationships
- Kubernetes routing relevance
- production routing troubleshooting methodology

## Issue #37 Completion Criteria

- [x] Routing table inspected
- [x] Default gateway identified
- [x] Route selection analyzed
- [x] Network path analyzed
- [x] Unreachable-network troubleshooting documented
- [x] AWS and Linux routing relationship documented
- [x] Kubernetes networking relevance documented

**Status: COMPLETE**
