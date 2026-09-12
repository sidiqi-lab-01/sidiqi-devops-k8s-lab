#!/usr/bin/env bash

# ============================================================
# Linux Network Diagnostics Script
# Issue #42 - Bash Network Diagnostics Script
#
# Purpose:
#   Collect structured Linux network troubleshooting data
#   without modifying the host network configuration.
#
# Usage:
#   ./scripts/network-diagnostics.sh
#   ./scripts/network-diagnostics.sh example.com
#   ./scripts/network-diagnostics.sh 172.31.22.252
#
# Optional argument:
#   A hostname or IP address to use as an additional
#   connectivity test target.
# ============================================================

set -u

TARGET="${1:-}"
DNS_TEST_HOST="example.com"
PUBLIC_TEST_IP="1.1.1.1"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

separator() {
    printf '%s\n' "======================================================================"
}

section() {
    echo
    separator
    printf ' %s\n' "$1"
    separator
}

pass() {
    printf '[PASS] %s\n' "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
    printf '[WARN] %s\n' "$1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_command() {
    local description="$1"
    shift

    printf '\n--- %s ---\n' "$description"

    if "$@"; then
        return 0
    else
        warn "Command failed: $description"
        return 1
    fi
}

section "NETWORK DIAGNOSTICS REPORT"

printf 'Timestamp      : %s\n' "$(date --iso-8601=seconds)"
printf 'Hostname       : %s\n' "$(hostname 2>/dev/null || echo unknown)"
printf 'User           : %s\n' "$(whoami 2>/dev/null || echo unknown)"
printf 'Kernel         : %s\n' "$(uname -r 2>/dev/null || echo unknown)"
printf 'Architecture   : %s\n' "$(uname -m 2>/dev/null || echo unknown)"

if [[ -n "$TARGET" ]]; then
    printf 'Custom target  : %s\n' "$TARGET"
else
    printf 'Custom target  : none\n'
fi

section "OPERATING SYSTEM"

if [[ -r /etc/os-release ]]; then
    cat /etc/os-release
    pass "Operating system information collected"
else
    warn "/etc/os-release is not readable"
fi

section "NETWORK INTERFACES"

if command_exists ip; then
    run_command "Interface summary" ip -brief address
    run_command "Interface link state" ip -brief link

    if ip -brief link | grep -q 'UP'; then
        pass "At least one network interface is UP"
    else
        fail "No UP network interfaces detected"
    fi
else
    fail "'ip' command is not available"
fi

section "IP ADDRESSING"

if command_exists ip; then
    run_command "IPv4 addresses" ip -4 address show
    run_command "IPv6 addresses" ip -6 address show

    if ip -4 address show scope global | grep -q 'inet '; then
        pass "At least one global IPv4 address detected"
    else
        fail "No global IPv4 address detected"
    fi
fi

section "ROUTING TABLE"

if command_exists ip; then
    run_command "IPv4 routing table" ip route show
    run_command "IPv6 routing table" ip -6 route show

    DEFAULT_ROUTE="$(ip route show default 2>/dev/null | head -n 1 || true)"

    if [[ -n "$DEFAULT_ROUTE" ]]; then
        pass "Default IPv4 route detected"
        printf 'Default route: %s\n' "$DEFAULT_ROUTE"
    else
        fail "No default IPv4 route detected"
    fi
fi

section "DEFAULT GATEWAY"

if command_exists ip; then
    DEFAULT_GATEWAY="$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')"

    if [[ -n "${DEFAULT_GATEWAY:-}" ]]; then
        printf 'Gateway: %s\n' "$DEFAULT_GATEWAY"

        if command_exists ping; then
            if ping -c 2 -W 2 "$DEFAULT_GATEWAY" >/dev/null 2>&1; then
                pass "Default gateway responds to ICMP"
            else
                warn "Default gateway did not respond to ICMP; ICMP may be filtered"
            fi
        else
            warn "'ping' command is not available"
        fi
    else
        warn "Unable to determine default gateway"
    fi
fi

section "DNS CONFIGURATION"

if [[ -r /etc/resolv.conf ]]; then
    run_command "/etc/resolv.conf" cat /etc/resolv.conf
else
    warn "/etc/resolv.conf is not readable"
fi

if command_exists resolvectl; then
    run_command "systemd-resolved status" resolvectl status
else
    warn "'resolvectl' is not available"
fi

section "DNS RESOLUTION TEST"

if command_exists getent; then
    if getent ahosts "$DNS_TEST_HOST" >/dev/null 2>&1; then
        pass "DNS resolution successful for $DNS_TEST_HOST"
        getent ahosts "$DNS_TEST_HOST" | head -n 5
    else
        fail "DNS resolution failed for $DNS_TEST_HOST"
    fi
else
    warn "'getent' command is not available"
fi

section "LISTENING PORTS AND SOCKETS"

if command_exists ss; then
    run_command "Listening TCP/UDP sockets" ss -tuln
    run_command "TCP socket summary" ss -s
else
    warn "'ss' command is not available"
fi

section "LOCAL NETWORK REACHABILITY"

if command_exists ping; then
    if ping -c 2 -W 2 "$PUBLIC_TEST_IP" >/dev/null 2>&1; then
        pass "Public IP reachability successful: $PUBLIC_TEST_IP"
    else
        warn "No ICMP response from $PUBLIC_TEST_IP; ICMP may be filtered"
    fi
else
    warn "'ping' command is not available"
fi

section "TCP CONNECTIVITY TEST"

if timeout 5 bash -c "cat < /dev/null > /dev/tcp/example.com/443" 2>/dev/null; then
    pass "TCP/443 connection to example.com succeeded"
else
    warn "TCP/443 connection to example.com failed"
fi

section "HTTP/HTTPS CONNECTIVITY"

if command_exists curl; then
    HTTP_CODE="$(
        curl \
            --silent \
            --show-error \
            --location \
            --max-time 5 \
            --output /dev/null \
            --write-out '%{http_code}' \
            https://example.com 2>/dev/null || true
    )"

    if [[ "$HTTP_CODE" =~ ^[23] ]]; then
        pass "HTTPS connectivity successful; HTTP status $HTTP_CODE"
    elif [[ -n "$HTTP_CODE" && "$HTTP_CODE" != "000" ]]; then
        warn "HTTPS endpoint responded with HTTP status $HTTP_CODE"
    else
        warn "HTTPS connectivity test failed"
    fi
else
    warn "'curl' command is not available"
fi

section "ARP / NEIGHBOR TABLE"

if command_exists ip; then
    run_command "Neighbor table" ip neigh show
fi

section "NETWORK STATISTICS"

if command_exists ip; then
    run_command "Interface statistics" ip -s link
fi

section "CUSTOM TARGET TEST"

if [[ -n "$TARGET" ]]; then

    printf 'Target: %s\n' "$TARGET"

    if command_exists getent; then
        if getent ahosts "$TARGET" >/dev/null 2>&1; then
            pass "Target can be resolved or interpreted: $TARGET"
        else
            warn "Unable to resolve target: $TARGET"
        fi
    fi

    if command_exists ping; then
        if ping -c 2 -W 2 "$TARGET" >/dev/null 2>&1; then
            pass "ICMP connectivity successful to $TARGET"
        else
            warn "ICMP connectivity failed to $TARGET"
        fi
    fi

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$TARGET/22" 2>/dev/null; then
        pass "TCP/22 reachable on $TARGET"
    else
        warn "TCP/22 not reachable on $TARGET"
    fi

else
    echo "No custom target supplied."
    echo "Example:"
    echo "  $0 172.31.22.252"
fi

section "NETWORK DIAGNOSTICS SUMMARY"

printf 'PASS checks : %d\n' "$PASS_COUNT"
printf 'WARN checks : %d\n' "$WARN_COUNT"
printf 'FAIL checks : %d\n' "$FAIL_COUNT"

echo

if (( FAIL_COUNT > 0 )); then
    echo "OVERALL STATUS: ATTENTION REQUIRED"
    EXIT_CODE=2
elif (( WARN_COUNT > 0 )); then
    echo "OVERALL STATUS: COMPLETED WITH WARNINGS"
    EXIT_CODE=0
else
    echo "OVERALL STATUS: HEALTHY"
    EXIT_CODE=0
fi

separator

exit "$EXIT_CODE"
