# DNS Configuration and Troubleshooting

## Overview

DNS (Domain Name System) translates hostnames into IP addresses and is a critical dependency for Linux, AWS, and Kubernetes environments.

This lab validates DNS configuration and resolution on an Ubuntu EC2 instance using `systemd-resolved`, `resolvectl`, `getent`, `nslookup`, and `dig`.

The troubleshooting approach covers:

* DNS resolver configuration
* `/etc/resolv.conf`
* `systemd-resolved`
* DNS servers
* Search domains
* `/etc/hosts`
* A, AAAA, MX, and NS records
* DNS caching
* DNS troubleshooting workflow
* AWS VPC DNS
* Kubernetes DNS/CoreDNS

---

## 1. Identify the Current Git Branch

### Command

```bash
git branch --show-current
```

### Result

```text
feature/dns-configuration-troubleshooting
```

This confirms that the DNS troubleshooting work is being performed on the dedicated feature branch.

---

## 2. Inspect `/etc/resolv.conf`

### Command

```bash
cat /etc/resolv.conf
```

### Observed Configuration

```text
nameserver 127.0.0.53
options edns0 trust-ad
search us-east-2.compute.internal
```

The file identifies itself as being managed by `systemd-resolved`.

The resolver address `127.0.0.53` is the local DNS stub listener provided by `systemd-resolved`.

The search domain is:

```text
us-east-2.compute.internal
```

### Important Concept

`/etc/resolv.conf` tells applications which resolver interface to use.

In this environment, applications send DNS requests to the local `systemd-resolved` stub rather than directly to the AWS upstream DNS server.

---

## 3. Inspect `systemd-resolved`

### Command

```bash
resolvectl status
```

### Observed Configuration

```text
Global
    Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
    resolv.conf mode: stub

Link 2 (ens5)
    Current Scopes: DNS
    Current DNS Server: 172.31.0.2
    DNS Servers: 172.31.0.2
    DNS Domain: us-east-2.compute.internal
```

The active network interface is:

```text
ens5
```

The configured upstream DNS server is:

```text
172.31.0.2
```

The system is operating in `stub` mode.

---

## 4. Inspect DNS Servers

### Command

```bash
resolvectl dns
```

### Result

```text
Global:
Link 2 (ens5): 172.31.0.2
```

This confirms that `ens5` is configured to use:

```text
172.31.0.2
```

for DNS resolution.

In an AWS VPC environment, this represents the AWS-provided DNS resolver associated with the VPC networking configuration.

---

## 5. Inspect DNS Search Domains

### Command

```bash
resolvectl domain
```

### Result

```text
Global:
Link 2 (ens5): us-east-2.compute.internal
```

The search domain allows unqualified hostnames to be resolved using the configured domain.

For example, a hostname such as:

```text
server1
```

may be searched as:

```text
server1.us-east-2.compute.internal
```

depending on resolver configuration and DNS records.

---

## 6. Test DNS Resolution with `getent`

### Command

```bash
getent hosts example.com
```

### Result

```text
2606:4700:10::ac42:93f3 example.com
2606:4700:10::6814:179a example.com
```

`getent` uses the system's configured name-service mechanisms.

This makes it particularly useful for testing whether normal Linux applications can resolve a hostname.

---

## 7. Test DNS Resolution with `nslookup`

### Command

```bash
nslookup example.com
```

### Result

The query successfully returned IPv4 and IPv6 addresses.

The configured resolver was:

```text
Server: 127.0.0.53
Address: 127.0.0.53#53
```

The result demonstrates that `nslookup` communicates with the local `systemd-resolved` stub.

---

## 8. Test DNS with `dig`

### Command

```bash
dig example.com
```

The query returned:

```text
status: NOERROR
```

The DNS server used was:

```text
127.0.0.53#53
```

The query returned two A records.

This confirms successful DNS resolution through the local resolver.

---

## 9. Query A Records

### Command

```bash
dig example.com A
```

The query returned IPv4 addresses including:

```text
172.66.147.243
104.20.23.154
```

An A record maps a hostname to an IPv4 address.

---

## 10. Query AAAA Records

### Command

```bash
dig example.com AAAA
```

The query returned IPv6 addresses including:

```text
2606:4700:10::6814:179a
2606:4700:10::ac42:93f3
```

An AAAA record maps a hostname to an IPv6 address.

---

## 11. Query MX Records

### Command

```bash
dig example.com MX
```

The query returned:

```text
example.com. 293 IN MX 0 .
```

An MX record identifies mail-exchange information for a domain.

The specific response indicates that the domain does not accept normal email delivery.

---

## 12. Query NS Records

### Command

```bash
dig example.com NS
```

The query returned authoritative name servers including:

```text
elliott.ns.cloudflare.com.
hera.ns.cloudflare.com.
```

NS records identify the DNS name servers authoritative for a domain.

---

## 13. Inspect `/etc/hosts`

### Command

```bash
cat /etc/hosts
```

The host file contained the normal local entries:

```text
127.0.0.1 localhost
::1 ip6-localhost ip6-loopback
```

There was no `example.com` entry.

This is important because `/etc/hosts` can override or provide local hostname resolution independently of DNS.

---

## 14. Validate with `resolvectl query`

### Command

```bash
resolvectl query example.com
```

The resolver successfully returned IPv4 and IPv6 addresses.

The result also showed:

```text
Data was acquired via local or encrypted transport: no
Data from: cache
```

This demonstrates that `systemd-resolved` was able to answer the request from its local DNS cache.

---

# DNS Troubleshooting Workflow

When DNS resolution fails, troubleshoot from the local configuration outward.

```text
Application
    ↓
getent
    ↓
/etc/hosts
    ↓
/etc/resolv.conf
    ↓
systemd-resolved
    ↓
Configured DNS server
    ↓
Network connectivity
    ↓
Authoritative DNS infrastructure
```

Recommended commands:

```bash
cat /etc/resolv.conf
resolvectl status
resolvectl dns
resolvectl domain
resolvectl query example.com
getent hosts example.com
nslookup example.com
dig example.com
```

---

# Common DNS Problems

## Problem 1: Hostname Does Not Resolve

Check:

```bash
getent hosts hostname
resolvectl query hostname
```

Then inspect:

```bash
cat /etc/resolv.conf
resolvectl status
```

Possible causes include:

* Incorrect DNS server
* Network connectivity failure
* Invalid search domain
* DNS server unavailable
* Firewall restrictions
* Incorrect `/etc/hosts`
* Application-specific resolver configuration

---

## Problem 2: `resolv.conf` Has the Wrong Server

Check:

```bash
cat /etc/resolv.conf
resolvectl status
```

If `systemd-resolved` is managing the file, avoid manually editing the generated stub configuration.

Instead investigate the network configuration and the DNS settings supplied to the interface.

---

## Problem 3: DNS Server Is Unreachable

Test network connectivity to the configured DNS server.

For example:

```bash
ping -c 3 172.31.0.2
```

Then inspect routing:

```bash
ip route
ip route get 172.31.0.2
```

DNS normally uses:

```text
UDP 53
```

and may also use:

```text
TCP 53
```

---

## Problem 4: `/etc/hosts` Overrides DNS

Check:

```bash
cat /etc/hosts
```

A hostname listed in `/etc/hosts` can resolve locally without querying external DNS.

This can cause unexpected behavior when the hosts file contains an outdated address.

---

## Problem 5: DNS Works on the Host but Not in an Application

Compare:

```bash
getent hosts example.com
```

with the application's behavior.

Applications may use different resolver libraries or configuration.

For containers and Kubernetes, also inspect the container's DNS configuration.

---

# AWS DNS Relevance

AWS EC2 instances depend heavily on DNS for:

* AWS service endpoints
* Internal hostnames
* VPC resources
* Package repositories
* External internet destinations
* Kubernetes infrastructure
* Application service discovery

In this lab, the EC2 instance is using:

```text
172.31.0.2
```

as its upstream DNS server and:

```text
127.0.0.53
```

as the local `systemd-resolved` stub.

When troubleshooting AWS DNS, also investigate:

```text
VPC DNS settings
Security Groups
Network ACLs
Route tables
DHCP options
Private hosted zones
Route 53
```

---

# Kubernetes DNS Relevance

Kubernetes relies heavily on DNS for service discovery.

Typical Kubernetes DNS resolution looks like:

```text
Application Pod
      ↓
/etc/resolv.conf
      ↓
CoreDNS
      ↓
Kubernetes Service / DNS records
      ↓
Pod or Service IP
```

Useful commands include:

```bash
kubectl get pods -n kube-system
kubectl get svc -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

To inspect DNS configuration inside a pod:

```bash
kubectl exec -it <pod-name> -- cat /etc/resolv.conf
```

To test DNS from a pod:

```bash
kubectl exec -it <pod-name> -- nslookup kubernetes.default
```

If DNS fails inside Kubernetes but works on the EC2 host, investigate:

* CoreDNS
* kube-dns Service
* Pod DNS configuration
* NetworkPolicy
* CNI networking
* Service records
* Cluster DNS configuration

---

# Production DNS Troubleshooting Example

Suppose an application reports:

```text
Unable to connect to database.example.internal
```

I would troubleshoot systematically:

```bash
getent hosts database.example.internal
resolvectl query database.example.internal
cat /etc/resolv.conf
resolvectl status
```

If the name does not resolve, determine whether the problem is:

```text
Application
    ↓
Linux resolver
    ↓
systemd-resolved
    ↓
DNS server
    ↓
AWS VPC networking
    ↓
Route 53 / authoritative DNS
```

If DNS resolves correctly, move to network and application connectivity:

```bash
ip route get <database-ip>
nc -zv <database-ip> <database-port>
```

This separates DNS problems from TCP connectivity problems.

---

# Key DNS Commands

```bash
cat /etc/resolv.conf
resolvectl status
resolvectl dns
resolvectl domain
resolvectl query example.com
getent hosts example.com
nslookup example.com
dig example.com
dig example.com A
dig example.com AAAA
dig example.com MX
dig example.com NS
cat /etc/hosts
```

---

# Key Takeaway

DNS troubleshooting should begin by determining:

1. Which resolver the host is using.
2. Which upstream DNS server is configured.
3. Whether the hostname resolves through normal system mechanisms.
4. Whether specific DNS record types resolve.
5. Whether `/etc/hosts` is affecting the result.
6. Whether DNS responses are cached.
7. Whether network connectivity to the DNS server works.
8. Whether AWS VPC or Kubernetes DNS infrastructure is involved.

The lab successfully validated DNS resolution through `systemd-resolved` and the AWS-provided DNS resolver.

**Issue #36 DNS Configuration and Troubleshooting — Documentation complete.**
