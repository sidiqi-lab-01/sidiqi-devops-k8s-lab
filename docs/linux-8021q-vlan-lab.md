# Linux IEEE 802.1Q VLAN Lab

## Purpose

This lab provides a hands-on implementation of IEEE 802.1Q VLAN networking inside an AWS EC2 Linux instance.

It extends the VLAN and virtual networking concepts documented in Issue #40 and implements the practical requirements tracked in Issue #64.

The objective is to demonstrate VLAN tagging, Linux network namespaces, virtual Ethernet interfaces, Layer-2 bridging, ARP/neighbor discovery, ICMP connectivity, packet capture, and safe network change management.

## Safety Design

The AWS EC2 management interface was intentionally excluded from the experimental VLAN configuration.

Management interface:

    ens5
    172.31.16.171/20

Default gateway:

    172.31.16.1

The VLAN lab operates entirely inside the Linux guest and does not modify the AWS management interface or its default route.

## Architecture

    AWS EC2 Linux Host
             |
             +----------------------+
             |                      |
            ens5                 br-vlan
       AWS Management        Linux L2 Bridge
       172.31.16.171         /            \
                           /                \
                     veth1-br            veth2-br
                         |                   |
                       veth1               veth2
                         |                   |
                    veth1.100           veth2.100
                     VLAN 100            VLAN 100
                         |                   |
                 192.168.100.11      192.168.100.12
                         |                   |
                    vlan-host1          vlan-host2

## Technologies Demonstrated

- Linux network namespaces
- Linux veth pairs
- Linux bridges
- IEEE 802.1Q
- VLAN ID 100
- IPv4 subnetting
- Layer-2 forwarding
- ARP/neighbor discovery
- ICMP testing
- tcpdump packet inspection
- AWS guest networking isolation

## Initial VLAN Validation

Before constructing the two-endpoint topology, an isolated VLAN interface was created using:

    Parent: vlp0
    VLAN interface: vlp0.100
    VLAN ID: 100
    Address: 192.168.100.1/24

Linux reported:

    vlan protocol 802.1Q id 100

The connected route was:

    192.168.100.0/24 dev vlp0.100

This proved that Linux VLAN support was available.

## Troubleshooting: Linux Interface Name Limit

The original VLAN interface name attempted was:

    vlan-lab-parent.100

Linux rejected the interface name.

A shorter parent name was used:

    vlp0

which allowed creation of:

    vlp0.100

This demonstrated the importance of validating operating-system constraints during network automation.

## Two-Endpoint VLAN Implementation

Two isolated network namespaces were created:

    vlan-host1
    vlan-host2

Two veth pairs provide virtual Ethernet connectivity:

    veth1 <-> veth1-br
    veth2 <-> veth2-br

The host-side interfaces connect to:

    br-vlan

which acts as a virtual Layer-2 Ethernet switch.

Each namespace creates an IEEE 802.1Q VLAN interface.

Host 1:

    veth1.100
    VLAN ID 100
    192.168.100.11/24

Host 2:

    veth2.100
    VLAN ID 100
    192.168.100.12/24

Linux confirmed on both endpoints:

    vlan protocol 802.1Q id 100

## Connectivity Validation

Host 1 to Host 2:

    192.168.100.11 -> 192.168.100.12

Result:

    4 packets transmitted
    4 received
    0% packet loss

Host 2 to Host 1:

    192.168.100.12 -> 192.168.100.11

Result:

    4 packets transmitted
    4 received
    0% packet loss

This confirmed bidirectional communication across VLAN 100.

## ARP / Neighbor Validation

Host 1 learned Host 2 through VLAN 100:

    192.168.100.12 dev veth1.100 REACHABLE

Host 2 learned Host 1 through VLAN 100:

    192.168.100.11 dev veth2.100 REACHABLE

This demonstrated Layer-2 neighbor discovery across the virtual VLAN topology.

## Packet-Level 802.1Q Validation

tcpdump was run on the bridge-side interface:

    tcpdump -i veth1-br -nn -e 'vlan 100 and icmp'

Traffic was generated from:

    192.168.100.11

to:

    192.168.100.12

The capture showed:

    ethertype 802.1Q (0x8100)
    vlan 100
    ethertype IPv4 (0x0800)

ICMP echo requests traveled:

    192.168.100.11 -> 192.168.100.12

and ICMP replies traveled:

    192.168.100.12 -> 192.168.100.11

Capture statistics:

    8 packets captured
    8 packets received by filter
    0 packets dropped by kernel

This provides packet-level proof that the traffic was IEEE 802.1Q tagged with VLAN ID 100.

## tcpdump Troubleshooting

The initial filter:

    vlan 100 icmp

failed because the filter expression lacked a Boolean operator.

The corrected filter was:

    vlan 100 and icmp

This allowed successful capture of VLAN-tagged ICMP traffic.

## AWS VPC Relationship

This VLAN exists inside the Linux guest operating system hosted on AWS EC2.

It should not be described as VLAN 100 being directly extended into the AWS VPC.

Standard AWS VPC networking abstracts the underlying physical Layer-2 infrastructure. AWS subnets and ENIs provide VPC networking, while this lab demonstrates IEEE 802.1Q behavior inside the EC2 operating system.

This distinction is important when comparing traditional data-center networking with cloud networking.

## Operational Safety

The live AWS interface was not modified.

After the VLAN implementation:

    ens5 = 172.31.16.171/20

The default route remained:

    default via 172.31.16.1 dev ens5

This demonstrates an important production principle:

> Experimental network changes should be isolated from the management path whenever possible.

## Reproducing the Lab

Run:

    sudo ./scripts/setup-vlan-lab.sh

The script creates the namespaces, bridge, veth pairs, VLAN interfaces, IP addressing, and connectivity tests.

## Cleanup

Run:

    sudo ./scripts/cleanup-vlan-lab.sh

The cleanup script removes the two-endpoint VLAN topology without modifying the AWS management interface.

The earlier standalone vlp0/vlp0.100 experiment is intentionally separate from these scripts.

## Interview Explanation

A concise explanation of this lab:

"I built an isolated IEEE 802.1Q VLAN lab inside an AWS EC2 Linux host. I used network namespaces to represent separate systems, veth pairs as virtual Ethernet connections, and a Linux bridge as a Layer-2 switch. Both endpoints used VLAN ID 100 with separate IP addresses. I validated bidirectional connectivity and ARP neighbor discovery, then used tcpdump to capture the Ethernet frames and verify the 0x8100 802.1Q EtherType and VLAN 100 tag. I deliberately kept the experiment isolated from the EC2 ens5 management interface so I would not disrupt remote access. I also distinguish this guest-level VLAN implementation from AWS VPC networking, which abstracts the underlying physical Layer-2 infrastructure."

## Issue

Implementation tracked by:

    Issue #64 - Build and Validate Linux 802.1Q VLAN Lab

Related conceptual documentation:

    Issue #40 - VLANs and Virtual Networking Concepts
