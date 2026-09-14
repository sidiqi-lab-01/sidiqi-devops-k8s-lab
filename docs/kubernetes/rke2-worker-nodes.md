# RKE2 Worker Node Deployment

## Overview

This implementation expands the RKE2 Kubernetes lab from a single server node to a three-node, multi-Availability-Zone cluster.

The cluster consists of one RKE2 server and two RKE2 worker nodes distributed across three AWS Availability Zones in `us-east-2`.

## Cluster Topology

| Node | Role | Availability Zone | Private IP |
|---|---|---|---|
| rke2-worker-01 | RKE2 Agent / Worker | us-east-2a | 172.31.3.177 |
| rke2-server-01 | Control Plane / etcd | us-east-2b | 172.31.29.36 |
| rke2-worker-02 | RKE2 Agent / Worker | us-east-2c | 172.31.38.166 |

All Kubernetes nodes use the dedicated RKE2 cluster security group.

## Worker Node Infrastructure

Both worker nodes were deployed with the following baseline configuration:

- Ubuntu 24.04 LTS
- `m7i-flex.large`
- 2 vCPUs
- Approximately 8 GiB memory
- 30 GiB encrypted gp3 root volume
- IMDSv2 required
- Dedicated RKE2 cluster security group
- RKE2 agent runtime
- containerd container runtime

## RKE2 Agent Configuration

Each worker uses `/etc/rancher/rke2/config.yaml`.

The configuration includes:

- RKE2 server endpoint on TCP 9345
- Secure cluster registration token
- Unique Kubernetes node name
- Environment label
- Worker role label

Example structure:

```yaml
server: https://172.31.29.36:9345
token: <secure-registration-token>
node-name: rke2-worker-01
node-label:
  - "node-role=sidiqi-rke2-worker"
  - "environment=lab"
The real registration token is never stored in Git.

Configuration permissions are restricted to root.

Security

Worker registration uses the RKE2 supervisor endpoint:

TCP 9345

Internal Kubernetes and RKE2 traffic is limited to the RKE2 cluster security group.

The cluster security rules support:

TCP 9345 — RKE2 node registration
TCP 6443 — Kubernetes API
TCP 10250 — kubelet
TCP 2379-2381 — embedded etcd server communication
UDP 8472 — Canal VXLAN
TCP 9099 — Canal health

Internal cluster ports are not exposed publicly.

Worker Validation

After installation, both RKE2 agents were enabled and started using systemd.

Cluster validation:

kubectl get nodes -o wide

Validated state:

rke2-server-01   Ready   control-plane,etcd
rke2-worker-01   Ready
rke2-worker-02   Ready

All nodes use:

Kubernetes: v1.36.4+rke2r1
Container runtime: containerd://2.3.4-k3s1.36
OS: Ubuntu 24.04.4 LTS
Node Labels

The cluster uses explicit labels to distinguish server and worker responsibilities.

Validation:

kubectl get nodes -L environment,node-role

Expected role model:

rke2-server-01   lab   sidiqi-rke2-server
rke2-worker-01   lab   sidiqi-rke2-worker
rke2-worker-02   lab   sidiqi-rke2-worker
Cluster Networking

RKE2 Canal networking is active on every node.

Validated components include:

Canal CNI
kube-proxy
CoreDNS
Traefik
Kubernetes service networking

Pod networking observed:

Server:     10.42.0.x
Worker-01:  10.42.1.x
Worker-02:  10.42.2.x

The Kubernetes service network uses the configured 10.43.0.0/16 service CIDR.

CoreDNS service:

10.43.0.10

Kubernetes API service:

10.43.0.1
Workload Validation

A temporary BusyBox workload was scheduled directly onto rke2-worker-01.

The workload successfully received a pod IP and resolved:

kubernetes.default.svc.cluster.local

through CoreDNS.

Observed result:

DNS server: 10.43.0.10
Kubernetes service: 10.43.0.1

This validated:

Kubernetes scheduling on worker nodes
Pod IP allocation
CNI functionality
Kubernetes service networking
CoreDNS resolution
Communication between worker workloads and cluster services
Final Architecture
                 DevOps Admin
                172.31.16.171
                       |
              kubectl / SSH
                       |
               rke2-server-01
                172.31.29.36
                 us-east-2b
                  /        \
                 /          \
        rke2-worker-01   rke2-worker-02
         172.31.3.177     172.31.38.166
          us-east-2a       us-east-2c

The resulting environment provides a functional multi-node RKE2 Kubernetes platform suitable for subsequent workload deployment, Helm, GitOps, CI/CD, storage, multi-site, and air-gapped exercises.

