# VLANs and Virtual Networking Concepts

## Purpose

This lab builds conceptual and practical understanding of:

- VLANs
- IEEE 802.1Q tagging
- Access and trunk ports
- Layer 2 and Layer 3 networking
- Linux bridges
- VMware virtual networking
- KVM and libvirt networking
- Network namespaces
- Kubernetes networking
- The relationship between physical and virtual networking

This work supports GitHub Issue #40:

    VLANs and Virtual Networking Concepts

---

# Lab Environment

The Linux administration host is an AWS EC2 instance.

Linux network interface inspection showed:

    Interface: ens5
    State: UP
    IPv4: 172.31.16.171/20
    MTU: 9001

The default route is:

    default via 172.31.16.1 dev ens5

Virtualization detection returned:

    amazon

This confirms the operating system is itself running inside an AWS virtualized environment.

---

# Current Network Interfaces

Command:

    ip -br link

Result:

    lo      UNKNOWN
    ens5    UP

Command:

    ip -br addr

Result:

    lo      127.0.0.1/8 ::1/128
    ens5    172.31.16.171/20

The EC2 instance currently has one primary Ethernet interface:

    ens5

There are no additional VLAN subinterfaces, bridges, bonds, or virtual Ethernet interfaces configured.

---

# VLAN Kernel Support

Command:

    lsmod | grep 8021q

Result:

    8021q
    garp
    mrp

The Linux kernel currently has the:

    8021q

module loaded.

This module provides support for IEEE 802.1Q VLAN tagging.

Therefore, the Linux kernel is capable of creating VLAN interfaces even though none are currently configured.

---

# What Is a VLAN?

A VLAN is a Virtual Local Area Network.

VLANs logically divide a physical Layer 2 network into separate broadcast domains.

Without VLANs, systems connected to the same Ethernet switching environment generally belong to the same Layer 2 broadcast domain.

With VLANs, a single physical switching infrastructure can support multiple logically isolated networks.

Example:

    Physical switch
       |
       +---- VLAN 10 - Engineering
       |
       +---- VLAN 20 - Operations
       |
       +---- VLAN 30 - Management

These VLANs may share the same physical switch but are logically separated.

---

# Why VLANs Are Used

VLANs are commonly used for:

- Network segmentation
- Security boundaries
- Broadcast-domain control
- Environment separation
- Department separation
- Management networks
- Storage networks
- Voice networks
- Application tiers
- Virtualization platforms
- Kubernetes infrastructure
- Multi-tenant environments

Example:

    VLAN 10
    Application servers

    VLAN 20
    Database servers

    VLAN 30
    Management interfaces

Even if all systems use the same physical switching infrastructure, VLANs provide logical isolation.

---

# VLAN IDs

IEEE 802.1Q uses VLAN identifiers.

Typical usable VLAN IDs are:

    1 through 4094

Although VLAN 1 exists, many enterprise environments avoid using it for sensitive workloads because it is commonly the default VLAN.

Example:

    VLAN 10 = Users
    VLAN 20 = Servers
    VLAN 30 = Storage
    VLAN 40 = Management

---

# IEEE 802.1Q Tagging

802.1Q inserts VLAN information into an Ethernet frame.

Conceptually:

    Ethernet frame without VLAN:

    [Destination MAC]
    [Source MAC]
    [EtherType]
    [Payload]

With an 802.1Q tag:

    [Destination MAC]
    [Source MAC]
    [802.1Q VLAN Tag]
    [EtherType]
    [Payload]

The VLAN tag identifies which VLAN the frame belongs to.

---

# Access Port

An access port normally carries traffic for one VLAN.

Example:

    Workstation
        |
        v
    Switch Port
    Access VLAN 10

The connected workstation usually does not need to know about VLAN tagging.

The switch assigns incoming untagged frames to VLAN 10.

Traffic leaving the access port is normally presented to the endpoint without an 802.1Q tag.

---

# Trunk Port

A trunk port carries multiple VLANs over one physical link.

Example:

                VLAN 10
                VLAN 20
                VLAN 30
                   |
                   v
    Switch ================= Hypervisor
             trunk link

The switch and hypervisor use VLAN tags to distinguish traffic.

A trunk is commonly used between:

- Switches
- Switch and hypervisor
- Switch and router
- Switch and firewall
- Switch and wireless controller
- Network appliances

---

# Access Versus Trunk

## Access Port

Usually:

    One VLAN
    Frames delivered untagged to endpoint
    Typical endpoint: workstation or simple server

## Trunk Port

Usually:

    Multiple VLANs
    Frames use 802.1Q tagging
    Typical endpoint: switch, router, firewall, or hypervisor

---

# Layer 2 Networking

Layer 2 is the Ethernet data-link layer.

Common Layer 2 concepts include:

- MAC addresses
- Ethernet frames
- Switches
- VLANs
- Broadcast domains
- Bridges
- Spanning Tree Protocol

A Layer 2 switch forwards traffic primarily using MAC-address tables.

Example:

    Host A
      |
      v
    Switch
      |
      v
    Host B

If Host A and Host B belong to the same VLAN and IP subnet, traffic can normally remain at Layer 2.

---

# Layer 3 Networking

Layer 3 is the IP networking layer.

Common Layer 3 concepts include:

- IPv4
- IPv6
- IP subnets
- Routers
- Routing tables
- Default gateways
- Inter-VLAN routing

Example:

    VLAN 10
    10.10.10.0/24
         |
         v
       Router
         |
         v
    VLAN 20
    10.10.20.0/24

Traffic between VLAN 10 and VLAN 20 requires a Layer 3 device.

---

# Layer 2 Versus Layer 3

A useful distinction is:

    Layer 2:
    Who is on my local Ethernet network?

    Layer 3:
    How do I reach another IP network?

Example:

    Same VLAN + same subnet
            |
            v
        Layer 2 switching

    Different VLAN/subnet
            |
            v
        Layer 3 routing

---

# Inter-VLAN Routing

VLANs create separate Layer 2 broadcast domains.

Systems in different VLANs usually require Layer 3 routing to communicate.

Example:

    VLAN 10
    10.10.10.0/24
         |
         |
      Layer 3
      Router
         |
         |
    VLAN 20
    10.10.20.0/24

Security policies can be applied at the router or firewall between VLANs.

---

# Linux VLAN Interfaces

Linux can create VLAN subinterfaces.

Example syntax:

    sudo ip link add link eth0 name eth0.10 type vlan id 10

This would create:

    eth0.10

representing:

    VLAN 10 on eth0

An IP address could then be assigned:

    sudo ip addr add 10.10.10.2/24 dev eth0.10

And the interface could be activated:

    sudo ip link set eth0.10 up

The physical interface would typically need to connect to a switch port carrying VLAN 10.

---

# Example Multiple VLAN Interfaces

A Linux server attached to a trunk might have:

    eth0
       |
       +-- eth0.10
       |     VLAN 10
       |
       +-- eth0.20
       |     VLAN 20
       |
       +-- eth0.30
             VLAN 30

Each VLAN interface can have separate Layer 3 configuration.

---

# Why We Did Not Create a VLAN Interface

The current EC2 instance is being administered remotely over:

    ens5

The active default route also uses:

    ens5

Changing VLAN configuration, bridging the interface, or changing routing on the active remote-management interface could interrupt SSH connectivity.

For this reason, Issue #40 uses safe inspection and architecture documentation rather than modifying the live interface.

This demonstrates an important operational principle:

    Understand the network dependency before changing the interface used for administration.

---

# Linux Bridge

A Linux bridge acts similarly to a software Ethernet switch.

Conceptually:

           Linux Bridge
              br0
          /    |     \
         /     |      \
       veth   tap0    eth0
        |       |       |
      Pod      VM     Physical NIC

The bridge forwards Ethernet frames between attached interfaces.

---

# Linux Bridge Use Cases

Linux bridges are commonly used by:

- KVM
- QEMU
- libvirt
- Containers
- Network namespaces
- Virtual appliances
- Kubernetes networking components
- Lab environments

---

# Bridge Inspection

Commands used:

    bridge link

and:

    bridge vlan show

No configured Linux bridge ports were displayed.

Therefore this host currently does not have an active Linux bridge topology.

---

# Linux Bridge Kernel Module

Command:

    lsmod | grep bridge

No bridge module was displayed in the current module list.

This means there is no evidence from this inspection that the bridge module is actively loaded as a module.

Linux networking functionality may also be built into the kernel depending on configuration.

The important operational observation is that no bridge interfaces are currently configured.

---

# Network Namespaces

Linux network namespaces provide isolated networking stacks.

Each network namespace can have its own:

- Interfaces
- IP addresses
- Routing table
- ARP/neighbor tables
- Firewall rules
- Sockets

Example:

    Host Linux
       |
       +-- namespace A
       |      |
       |      +-- veth0
       |
       +-- namespace B
              |
              +-- veth1

Network namespaces are fundamental to Linux container networking.

---

# Namespace Inspection

Command:

    ip netns list

No network namespaces were listed.

This means no persistent namespaces created through:

    ip netns

currently exist on this host.

---

# Virtual Ethernet Interfaces

Linux provides virtual Ethernet devices called:

    veth pairs

A veth pair behaves like a virtual Ethernet cable.

Conceptually:

    veth-host <==============> veth-container

A packet entering one end emerges from the other.

Containers often use veth pairs to connect their network namespace to the host networking environment.

---

# KVM Networking

KVM stands for:

    Kernel-based Virtual Machine

KVM allows Linux to operate as a hypervisor when supported hardware virtualization is available.

A common KVM networking architecture is:

    Physical NIC
         |
         v
    Linux Bridge
       br0
      / | \
     /  |  \
   VM1 VM2 VM3

Each VM has a virtual NIC connected to the Linux bridge.

The Linux bridge behaves like a virtual switch.

---

# KVM Device Inspection

Command:

    ls -l /dev/kvm

Result:

    /dev/kvm not present

Therefore this EC2 guest does not currently expose the KVM device.

This host is not being used as a local KVM hypervisor in this lab.

---

# Nested Virtualization

Running a hypervisor inside another virtual machine is known as:

    Nested virtualization

Conceptually:

    Physical hardware
          |
          v
    Cloud/host hypervisor
          |
          v
       EC2 VM
          |
          v
       KVM
          |
          v
      Nested VMs

Support for nested virtualization depends on the cloud platform, instance type, processor capabilities, and provider configuration.

This lab does not rely on nested virtualization.

---

# QEMU

QEMU provides machine and device emulation and is commonly paired with KVM.

Together:

    QEMU + KVM

can provide high-performance Linux virtual machines.

QEMU commonly provides:

- Virtual hardware
- Virtual disks
- Virtual network adapters
- Machine emulation

KVM provides hardware-assisted virtualization through the Linux kernel.

---

# libvirt

libvirt is a virtualization-management layer commonly used with KVM and QEMU.

It manages resources such as:

- Virtual machines
- Virtual disks
- Virtual networks
- Bridges
- NAT networks
- Storage pools

Common tools include:

    virsh
    virt-install
    virt-manager

No libvirt packages were detected on this host during inspection.

---

# Common libvirt Network

A common default libvirt topology is:

       VM
        |
     vnet0
        |
        v
     virbr0
        |
        v
       NAT
        |
        v
    Physical NIC
        |
        v
     Internet

The virtual machine may receive a private IP behind a Linux NAT bridge.

---

# Bridged VM Networking

An alternative design directly bridges VMs to the external network.

Example:

          VM1
           |
         tap0
           |
           v
          br0
           |
           v
         eth0
           |
           v
     Physical Switch

The VM can then participate more directly in the upstream Layer 2 network.

---

# VLAN-Aware Hypervisor

A hypervisor can connect to an upstream trunk and place VMs into specific VLANs.

Example:

                      VLAN trunk
                          |
                          v
    Physical Switch ============== Hypervisor
                                 |
                                 v
                             vSwitch/br0
                            /    |    \
                           /     |     \
                      VM-A     VM-B    VM-C
                     VLAN10   VLAN20  VLAN30

This allows many isolated networks to share one physical NIC.

---

# VMware Networking

VMware uses software-defined virtual switching.

Common VMware components include:

- vNIC
- vSwitch
- Port group
- VMkernel interface
- Physical NIC/uplink
- VLAN configuration

---

# VMware vSwitch

A VMware vSwitch behaves conceptually like a Layer 2 Ethernet switch implemented in software.

Example:

      VM1
       |
      vNIC
       |
       v
    Port Group
       |
       v
     vSwitch
       |
       v
     vmnic0
       |
       v
    Physical Switch

---

# VMware Port Groups

A port group defines network properties for virtual machines.

Examples:

    Production-PortGroup
    VLAN 10

    Management-PortGroup
    VLAN 20

    Storage-PortGroup
    VLAN 30

Virtual machines connect their virtual NICs to port groups.

---

# VMware VLAN Tagging

A VMware environment can map port groups to VLAN IDs.

Example:

    Port Group: Application
    VLAN ID: 10

    Port Group: Database
    VLAN ID: 20

    Port Group: Management
    VLAN ID: 30

The physical uplink may connect to a trunk port on the physical switch.

---

# VMware Networking Architecture

Example:

    Physical Switch
       trunk
         |
         v
      vmnic0
         |
         v
      vSwitch0
      /   |   \
     /    |    \
 VLAN10 VLAN20 VLAN30
   |      |      |
  VM1    VM2    Mgmt

The concept is very similar to Linux bridge and KVM networking even though the implementation and management tools are different.

---

# VMware Versus KVM Networking

## VMware

Common components:

    vSwitch
    Distributed vSwitch
    Port Groups
    VMkernel adapters
    vmnic uplinks

## KVM/Linux

Common components:

    Linux bridges
    Open vSwitch
    TAP interfaces
    vnet interfaces
    libvirt networks
    veth devices

Both solve a similar problem:

    Connect virtual workloads to networks.

---

# Open vSwitch

Open vSwitch, commonly abbreviated:

    OVS

is a software virtual switch.

It supports advanced networking features such as:

- VLANs
- Trunks
- Tunnels
- VXLAN
- GRE
- OpenFlow
- Virtual machine connectivity
- Container connectivity

OVS has historically been used in virtualization and software-defined networking environments.

---

# Cloud Networking and VLANs

Public clouds typically abstract much of the physical VLAN infrastructure away from customers.

In AWS, users normally work with constructs such as:

- VPCs
- Subnets
- Route tables
- Security Groups
- Network ACLs
- Elastic Network Interfaces

The cloud provider manages the underlying physical switching and virtualization infrastructure.

Therefore:

    AWS subnet

should not automatically be treated as identical to:

    Traditional Ethernet VLAN

They serve some similar segmentation purposes, but operate within different abstractions and architectures.

---

# AWS VPC Networking

The current EC2 host participates in an AWS VPC.

From the Linux guest perspective:

    ens5
       |
       v
    AWS virtual network interface
       |
       v
    AWS VPC networking
       |
       v
    Subnet / routing
       |
       v
    Other AWS resources

The physical switching details are abstracted from the guest.

---

# Kubernetes Networking Relationship

Kubernetes networking builds heavily on Linux networking concepts.

Important underlying technologies may include:

- Network namespaces
- veth pairs
- Bridges
- Routing
- iptables
- nftables
- eBPF
- VXLAN
- BGP
- Overlay networking
- Underlay networking

---

# Kubernetes Pod Networking

Every Kubernetes pod normally receives its own IP address.

Conceptually:

       Kubernetes Node
       ------------------------
       |                      |
       | Host network         |
       |                      |
       |    veth pair         |
       |       |              |
       |       v              |
       |   Pod namespace      |
       |       |              |
       |       v              |
       |    eth0              |
       |                      |
       ------------------------

The pod has its own network namespace while the host connects it to the wider cluster network.

---

# Kubernetes CNI

CNI means:

    Container Network Interface

A CNI plugin configures networking for pods.

Examples include:

- Calico
- Cilium
- Flannel
- AWS VPC CNI

A CNI implementation may configure:

- Pod interfaces
- IP addresses
- Routes
- veth pairs
- Bridges
- Overlay tunnels
- Network policy

---

# Overlay Networking

An overlay network creates a logical network over an existing physical or virtual network.

Example:

    Node A
    Pod 10.244.1.10
         |
         v
       VXLAN
         |
    =========================
       Underlay IP network
    =========================
         |
         v
       VXLAN
         |
    Node B
    Pod 10.244.2.20

The underlying infrastructure transports encapsulated packets.

---

# Underlay Networking

The underlay is the actual network carrying traffic.

Examples:

- Physical Ethernet
- VLANs
- Routed IP networks
- Cloud VPC networks

An overlay may run on top of that underlay.

---

# VXLAN

VXLAN stands for:

    Virtual Extensible LAN

It encapsulates Layer 2 traffic inside UDP packets over a Layer 3 network.

VXLAN is commonly used for scalable virtual networking.

Conceptually:

    Original Ethernet Frame
           |
           v
       VXLAN Encapsulation
           |
           v
        UDP/IP Network
           |
           v
       VXLAN Decapsulation
           |
           v
    Original Ethernet Frame

---

# VLAN Versus VXLAN

VLAN:

    Traditional Layer 2 segmentation
    Uses 802.1Q
    Approximately 4094 VLAN IDs

VXLAN:

    Overlay technology
    Uses a 24-bit VNI
    Supports a much larger logical network space
    Operates across routed Layer 3 networks

---

# Kubernetes and VLANs

Kubernetes does not require traditional VLANs for pod networking.

However VLANs may still be used in the underlying infrastructure.

Example:

    VLAN 10
    Kubernetes management

    VLAN 20
    Worker-node traffic

    VLAN 30
    Storage traffic

    VLAN 40
    External load balancer traffic

The Kubernetes CNI then implements pod networking on top of or alongside that network architecture.

---

# Kubernetes Node Network Example

    Physical Switch
          |
       VLAN trunk
          |
          v
    Kubernetes Node
       |
       +-- Management network
       |
       +-- Storage network
       |
       +-- Pod networking
       |
       +-- Service connectivity

The exact implementation depends on the cluster architecture.

---

# VMware and Kubernetes

Kubernetes clusters can run inside VMware virtual machines.

Example:

    Physical Servers
          |
          v
       VMware
          |
          v
    Virtual Machines
       /       \
      /         \
 Control Plane  Workers
                   |
                   v
              Kubernetes
                   |
                   v
                  Pods

In such a design, multiple networking layers may exist:

    Physical network
    VLANs
    VMware vSwitches
    VM virtual NICs
    Linux networking
    Kubernetes CNI
    Pod networking

Troubleshooting requires understanding every layer.

---

# KVM and Kubernetes

The same concept applies with KVM:

    Physical NIC
         |
         v
    Linux Bridge
         |
         v
       KVM VMs
         |
         v
      Linux OS
         |
         v
    Kubernetes Node
         |
         v
         CNI
         |
         v
        Pods

---

# Multi-Layer Troubleshooting

If a Kubernetes pod cannot reach another system in a virtualized environment, possible layers include:

    Application
        |
        v
    Pod socket
        |
        v
    Pod network namespace
        |
        v
    veth interface
        |
        v
    CNI configuration
        |
        v
    Node routing
        |
        v
    Virtual switch / bridge
        |
        v
    Hypervisor uplink
        |
        v
    VLAN
        |
        v
    Physical switch
        |
        v
    Router / firewall

This is why strong Linux and networking fundamentals matter for Kubernetes operations.

---

# Practical Commands

Useful Linux VLAN commands:

    ip -d link show

    lsmod | grep 8021q

    ip link add link eth0 name eth0.10 type vlan id 10

    ip link set eth0.10 up

    ip addr add 10.10.10.2/24 dev eth0.10

Useful bridge commands:

    bridge link

    bridge vlan show

    ip link show type bridge

Useful namespace commands:

    ip netns list

    ip netns add lab1

Useful virtualization commands:

    systemd-detect-virt

    ls -l /dev/kvm

    virsh list --all

Useful routing commands:

    ip route

    ip route get <destination>

---

# Safe Change Management

Networking changes can easily disconnect a remotely administered Linux server.

Before changing:

- VLAN interfaces
- Bridges
- Bonding
- IP addressing
- Default routes
- Firewall rules

an engineer should understand:

- Current management path
- Console access
- Recovery mechanism
- Rollback procedure
- Change window
- Dependency impact

A senior engineer does not experiment blindly with the interface carrying the active SSH session.

---

# Interview Explanation

A concise interview response could be:

    VLANs provide Layer 2 network segmentation using IEEE 802.1Q tags.
    An access port generally carries one VLAN, while a trunk can carry
    multiple tagged VLANs.

    Traffic inside the same VLAN can usually be switched at Layer 2,
    while communication between different VLANs requires Layer 3 routing.

    In Linux virtualization, a Linux bridge behaves similarly to a
    software Ethernet switch. KVM virtual machines can connect through
    TAP or vnet interfaces to a Linux bridge, which can then connect
    to a physical NIC or VLAN trunk.

    VMware uses similar concepts through vSwitches, port groups, virtual
    NICs, and physical uplinks.

    Kubernetes builds on many of the same Linux networking primitives,
    including namespaces, veth pairs, routing, overlays, and CNI plugins.

    When troubleshooting, I follow the entire path from the pod or VM,
    through the virtual network, hypervisor, VLAN, physical network,
    and routing layer instead of looking at only one component.

---

# Senior-Level Design Perspective

A senior engineer should consider more than whether VLAN connectivity works.

Important questions include:

    What security boundary does the VLAN provide?

    Which systems need Layer 2 adjacency?

    Where does Layer 3 routing occur?

    Is east-west traffic filtered?

    How are management, storage, and application networks separated?

    Are trunk VLANs explicitly allowed?

    How are hypervisor networks standardized?

    How does Kubernetes CNI interact with the underlay?

    Are overlays needed?

    What is the failure domain?

    How is configuration automated?

    How is network state monitored?

    How will the architecture work in an air-gapped environment?

---

# Air-Gapped Environment Consideration

In an air-gapped environment, virtual networking design becomes especially important.

Typical concerns include:

- Internal management VLANs
- Internal Kubernetes networks
- Private container registries
- Internal DNS
- Internal NTP
- Storage networks
- Restricted administrative access
- Controlled routing between security zones
- No dependence on public cloud services

A well-designed environment clearly defines:

    Physical network
    VLAN segmentation
    Hypervisor networking
    Kubernetes node networking
    Pod networking
    Security controls

---

# Lab Findings

The current host showed:

    ens5:
        UP

    IPv4:
        172.31.16.171/20

    VLAN kernel module:
        8021q loaded

    VLAN subinterfaces:
        none configured

    Linux bridges:
        none configured

    Network namespaces:
        none configured

    Virtualization environment:
        Amazon

    /dev/kvm:
        not present

    QEMU/libvirt packages:
        not detected

    Default gateway:
        172.31.16.1

The host supports Linux VLAN functionality but is not currently configured as a VLAN trunk, bridge-based hypervisor, or KVM virtualization host.

---

# Completion Criteria

Issue #40 requires:

- VLAN architecture documented.
- VMware/KVM networking concepts explained.
- Kubernetes networking relationship documented.

Results:

- [x] VLAN concepts documented.
- [x] IEEE 802.1Q explained.
- [x] VLAN IDs explained.
- [x] Access ports explained.
- [x] Trunk ports explained.
- [x] Layer 2 networking explained.
- [x] Layer 3 networking explained.
- [x] Inter-VLAN routing explained.
- [x] Linux VLAN kernel support inspected.
- [x] Linux VLAN interface concepts documented.
- [x] Linux bridges explained.
- [x] Bridge state inspected.
- [x] Network namespaces explained.
- [x] Namespace state inspected.
- [x] veth networking explained.
- [x] KVM networking explained.
- [x] KVM availability inspected.
- [x] QEMU/libvirt concepts explained.
- [x] VMware vSwitch concepts explained.
- [x] VMware port groups explained.
- [x] VMware VLAN architecture documented.
- [x] Kubernetes pod networking explained.
- [x] CNI networking explained.
- [x] Overlay networking explained.
- [x] VXLAN explained.
- [x] Kubernetes/VLAN relationship documented.
- [x] Multi-layer troubleshooting model documented.
- [x] Safe network change practices documented.

---

# Conclusion

VLANs provide Layer 2 network segmentation through IEEE 802.1Q tagging.

Access ports typically connect endpoints to one VLAN, while trunk ports carry multiple VLANs using tags.

Communication between VLANs requires Layer 3 routing.

Linux supports VLAN networking through the 8021q kernel functionality and can implement software switching through Linux bridges.

KVM commonly connects virtual machines through Linux bridges or virtual-switch technologies.

VMware provides similar capabilities through vSwitches, port groups, virtual NICs, and physical uplinks.

Kubernetes uses many of the same fundamental Linux networking concepts, including namespaces, veth pairs, routing, overlays, and virtual interfaces.

The current AWS EC2 host has 802.1Q support available but does not currently contain VLAN interfaces, Linux bridges, network namespaces, or KVM virtualization.

The practical lesson is that VLANs, hypervisor networking, cloud networking, and Kubernetes networking are separate layers of one larger end-to-end network architecture.
