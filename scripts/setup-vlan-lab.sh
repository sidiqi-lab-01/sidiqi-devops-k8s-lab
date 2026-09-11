#!/usr/bin/env bash
set -euo pipefail

echo "=== Linux 802.1Q VLAN 100 Lab ==="

# Safety check: never modify the AWS management interface.
echo
echo "AWS management interface before lab:"
ip -br addr show ens5
ip route | head -10

echo
echo "Cleaning previous VLAN lab..."
ip netns del vlan-host1 2>/dev/null || true
ip netns del vlan-host2 2>/dev/null || true
ip link del br-vlan 2>/dev/null || true
ip link del veth1-br 2>/dev/null || true
ip link del veth2-br 2>/dev/null || true

echo
echo "Creating namespaces..."
ip netns add vlan-host1
ip netns add vlan-host2

echo "Creating virtual Ethernet pairs..."
ip link add veth1 type veth peer name veth1-br
ip link add veth2 type veth peer name veth2-br

ip link set veth1 netns vlan-host1
ip link set veth2 netns vlan-host2

echo "Creating Linux Layer-2 bridge..."
ip link add br-vlan type bridge
ip link set br-vlan up

ip link set veth1-br master br-vlan
ip link set veth2-br master br-vlan
ip link set veth1-br up
ip link set veth2-br up

echo "Enabling namespace interfaces..."
ip netns exec vlan-host1 ip link set lo up
ip netns exec vlan-host1 ip link set veth1 up

ip netns exec vlan-host2 ip link set lo up
ip netns exec vlan-host2 ip link set veth2 up

echo "Creating IEEE 802.1Q VLAN 100 interfaces..."
ip netns exec vlan-host1 \
  ip link add link veth1 name veth1.100 type vlan id 100

ip netns exec vlan-host2 \
  ip link add link veth2 name veth2.100 type vlan id 100

echo "Assigning VLAN addresses..."
ip netns exec vlan-host1 \
  ip addr add 192.168.100.11/24 dev veth1.100

ip netns exec vlan-host2 \
  ip addr add 192.168.100.12/24 dev veth2.100

ip netns exec vlan-host1 ip link set veth1.100 up
ip netns exec vlan-host2 ip link set veth2.100 up

echo
echo "=== VERIFY VLAN HOST 1 ==="
ip netns exec vlan-host1 ip -br addr
ip netns exec vlan-host1 ip -d link show veth1.100

echo
echo "=== VERIFY VLAN HOST 2 ==="
ip netns exec vlan-host2 ip -br addr
ip netns exec vlan-host2 ip -d link show veth2.100

echo
echo "=== VERIFY BRIDGE ==="
ip -br link show br-vlan
bridge link

echo
echo "=== TEST HOST1 -> HOST2 ==="
ip netns exec vlan-host1 ping -c 4 192.168.100.12

echo
echo "=== TEST HOST2 -> HOST1 ==="
ip netns exec vlan-host2 ping -c 4 192.168.100.11

echo
echo "=== NEIGHBOR TABLES ==="
ip netns exec vlan-host1 ip neigh
ip netns exec vlan-host2 ip neigh

echo
echo "=== AWS MANAGEMENT INTERFACE AFTER LAB ==="
ip -br addr show ens5
ip route | head -10

echo
echo "VLAN 100 lab successfully created."
