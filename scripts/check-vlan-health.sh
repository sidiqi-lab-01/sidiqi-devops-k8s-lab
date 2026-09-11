#!/usr/bin/env bash
set -u

FAILURES=0

pass() {
  echo "[PASS] $1"
}

fail() {
  echo "[FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

info() {
  echo "[INFO] $1"
}

echo "========================================"
echo " Linux 802.1Q VLAN 100 Health Check"
echo "========================================"

echo
echo "=== 1. AWS MANAGEMENT INTERFACE ==="

if ip link show ens5 >/dev/null 2>&1; then
  pass "ens5 exists"
else
  fail "ens5 does not exist"
fi

if ip -br addr show ens5 | grep -q "172.31.16.171/20"; then
  pass "ens5 has expected management IP 172.31.16.171/20"
else
  fail "ens5 does not have expected management IP"
fi

if ip route | grep -q "^default via 172.31.16.1 dev ens5"; then
  pass "default route still uses 172.31.16.1 via ens5"
else
  fail "expected AWS default route not found"
fi

echo
echo "=== 2. NETWORK NAMESPACES ==="

if ip netns list | grep -q "^vlan-host1"; then
  pass "vlan-host1 exists"
else
  fail "vlan-host1 missing"
fi

if ip netns list | grep -q "^vlan-host2"; then
  pass "vlan-host2 exists"
else
  fail "vlan-host2 missing"
fi

echo
echo "=== 3. LINUX BRIDGE ==="

if ip link show br-vlan >/dev/null 2>&1; then
  pass "br-vlan exists"
else
  fail "br-vlan missing"
fi

if ip -br link show br-vlan 2>/dev/null | grep -q "UP"; then
  pass "br-vlan is UP"
else
  fail "br-vlan is not UP"
fi

if bridge link | grep -q "veth1-br.*master br-vlan.*state forwarding"; then
  pass "veth1-br is forwarding through br-vlan"
else
  fail "veth1-br is not forwarding through br-vlan"
fi

if bridge link | grep -q "veth2-br.*master br-vlan.*state forwarding"; then
  pass "veth2-br is forwarding through br-vlan"
else
  fail "veth2-br is not forwarding through br-vlan"
fi

echo
echo "=== 4. VLAN 100 INTERFACES ==="

if ip netns exec vlan-host1 ip -d link show veth1.100 2>/dev/null | grep -q "vlan protocol 802.1Q id 100"; then
  pass "veth1.100 is configured for IEEE 802.1Q VLAN 100"
else
  fail "veth1.100 VLAN 100 configuration missing"
fi

if ip netns exec vlan-host2 ip -d link show veth2.100 2>/dev/null | grep -q "vlan protocol 802.1Q id 100"; then
  pass "veth2.100 is configured for IEEE 802.1Q VLAN 100"
else
  fail "veth2.100 VLAN 100 configuration missing"
fi

echo
echo "=== 5. VLAN IP ADDRESSING ==="

if ip netns exec vlan-host1 ip -br addr show veth1.100 2>/dev/null | grep -q "192.168.100.11/24"; then
  pass "vlan-host1 has 192.168.100.11/24"
else
  fail "vlan-host1 IP address incorrect or missing"
fi

if ip netns exec vlan-host2 ip -br addr show veth2.100 2>/dev/null | grep -q "192.168.100.12/24"; then
  pass "vlan-host2 has 192.168.100.12/24"
else
  fail "vlan-host2 IP address incorrect or missing"
fi

echo
echo "=== 6. CONNECTIVITY ==="

if ip netns exec vlan-host1 ping -c 2 -W 2 192.168.100.12 >/dev/null 2>&1; then
  pass "vlan-host1 can reach vlan-host2"
else
  fail "vlan-host1 cannot reach vlan-host2"
fi

if ip netns exec vlan-host2 ping -c 2 -W 2 192.168.100.11 >/dev/null 2>&1; then
  pass "vlan-host2 can reach vlan-host1"
else
  fail "vlan-host2 cannot reach vlan-host1"
fi

echo
echo "=== 7. ARP / NEIGHBOR DISCOVERY ==="

if ip netns exec vlan-host1 ip neigh show 192.168.100.12 2>/dev/null | grep -Eq "REACHABLE|STALE|DELAY|PROBE"; then
  pass "vlan-host1 has neighbor entry for 192.168.100.12"
else
  fail "vlan-host1 neighbor entry for 192.168.100.12 missing"
fi

if ip netns exec vlan-host2 ip neigh show 192.168.100.11 2>/dev/null | grep -Eq "REACHABLE|STALE|DELAY|PROBE"; then
  pass "vlan-host2 has neighbor entry for 192.168.100.11"
else
  fail "vlan-host2 neighbor entry for 192.168.100.11 missing"
fi

echo
echo "=== 8. CURRENT STATE SUMMARY ==="

info "Namespaces:"
ip netns list

echo
info "Bridge:"
ip -br link show br-vlan 2>/dev/null || true

echo
info "Host 1:"
ip netns exec vlan-host1 ip -br addr 2>/dev/null || true

echo
info "Host 2:"
ip netns exec vlan-host2 ip -br addr 2>/dev/null || true

echo
echo "========================================"

if [ "$FAILURES" -eq 0 ]; then
  echo "VLAN HEALTH STATUS: HEALTHY"
  echo "All VLAN 100 checks passed."
  exit 0
else
  echo "VLAN HEALTH STATUS: UNHEALTHY"
  echo "$FAILURES check(s) failed."
  exit 1
fi
