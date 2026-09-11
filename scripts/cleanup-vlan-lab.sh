#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning Linux VLAN Lab ==="

ip netns del vlan-host1 2>/dev/null || true
ip netns del vlan-host2 2>/dev/null || true
ip link del br-vlan 2>/dev/null || true
ip link del veth1-br 2>/dev/null || true
ip link del veth2-br 2>/dev/null || true

echo
echo "VLAN endpoint lab removed."

echo
echo "AWS management interface:"
ip -br addr show ens5
ip route | head -10
