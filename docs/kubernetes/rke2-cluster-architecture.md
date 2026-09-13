# RKE2 Kubernetes Cluster Architecture

## Purpose

This document defines the RKE2 Kubernetes architecture for the
sidiqi-devops-k8s-lab project.

The design supports hands-on Kubernetes implementation while documenting
how the architecture would evolve into a production high-availability design.

## Lab Architecture

The lab uses:

- One dedicated RKE2 server node
- Two dedicated RKE2 worker nodes
- Existing DevOps admin EC2 as the management workstation
- Embedded etcd on the RKE2 server
- RKE2-managed containerd runtime
- Kubernetes networking and service discovery
- Dedicated AWS security-group controls

The existing DevOps admin server remains separate from the Kubernetes cluster.

Architecture:

    DevOps Admin EC2
          |
          | kubectl / SSH / Ansible
          |
    RKE2 Server 01
    Control Plane + etcd
          |
       +--+--+
       |     |
    Worker1 Worker2
       |     |
       +--+--+
          |
      Application

## Node Roles

### Management Node

Responsibilities:

- Git and GitHub operations
- AWS CLI
- Ansible
- kubectl administration
- Kubernetes troubleshooting
- Cluster automation

The management node is not a Kubernetes cluster member.

### RKE2 Server

Responsibilities:

- Kubernetes API server
- Scheduler
- Controller manager
- RKE2 supervisor
- Embedded etcd
- Cluster control-plane services

### RKE2 Workers

Responsibilities:

- kubelet
- containerd
- application pods
- Kubernetes networking
- workload execution

## Network Requirements

Primary cluster ports include:

| Port | Protocol | Purpose |
|---|---|---|
| 6443 | TCP | Kubernetes API |
| 9345 | TCP | RKE2 registration and supervisor |
| 10250 | TCP | Kubelet |
| 2379 | TCP | etcd client |
| 2380 | TCP | etcd peer |
| 2381 | TCP | etcd metrics |
| 8472 | UDP | Flannel VXLAN when applicable |
| 30000-32767 | TCP | Kubernetes NodePort when required |

Internal Kubernetes networking ports must not be exposed broadly to the Internet.

AWS security groups should use security-group references for cluster
communication wherever practical.

## Datastore

The lab uses embedded etcd on the RKE2 server.

Lab:

    RKE2 Server 01
          |
      Embedded etcd

Production:

    Server 01
    Server 02
    Server 03
        |
    etcd quorum

Production RKE2 control planes should use an odd number of server nodes.

## Node Registration

Agents register with the RKE2 server using:

    https://SERVER:9345

Authentication uses the RKE2 node registration token.

The registration token must not be committed to Git.

## Kubernetes API

The Kubernetes API is exposed by RKE2 servers on TCP 6443.

Lab administration can initially use the private address of the RKE2 server.

Production environments should use a stable DNS or load-balancer endpoint
in front of multiple server nodes.

## Certificates

RKE2 manages Kubernetes certificates.

Production designs using a fixed API or registration DNS name should include
that hostname or address in the TLS SAN configuration.

## Container Runtime

RKE2 uses containerd through the Kubernetes Container Runtime Interface.

Docker Engine is not required on Kubernetes nodes.

Operational tooling includes:

- kubectl
- crictl
- ctr
- containerd
- runc

## Application Architecture

The existing Docker Compose application will later be migrated to Kubernetes.

    Browser
       |
    Frontend
       |
      API
     /   \
  Users Orders
           |
       PostgreSQL

Kubernetes resources will include:

- Deployments
- Services
- ConfigMaps
- Secrets
- Readiness probes
- Liveness probes
- Persistent storage
- Resource requests and limits

## Production Architecture

A production implementation should evolve toward:

    Stable Registration/API Endpoint
                 |
        +--------+--------+
        |        |        |
     Server1  Server2  Server3
        |        |        |
        +----- etcd -------+
                 |
        +--------+--------+
        |                 |
     Worker1            Worker2+
        |                 |
        +---- Workloads ---+

Production considerations include:

- Three or more odd-numbered RKE2 servers
- Load-balanced or stable registration endpoint
- Multiple worker nodes
- Failure-domain separation
- Restricted security groups
- Backup and restore procedures
- Monitoring and logging
- Secrets management
- Persistent storage
- Capacity planning
- Certificate lifecycle management

## Failure Scenarios to Test

The implementation milestones will test:

1. Worker node unavailable
2. Pod failure and recreation
3. Service discovery failure
4. Invalid configuration
5. Readiness probe failure
6. Liveness probe failure
7. Application dependency failure
8. Rolling deployment
9. Deployment rollback

## Milestone Mapping

Issue 77:
Design RKE2 Kubernetes Cluster Architecture.

Issue 78:
Install and validate the RKE2 server.

Issue 79:
Join and validate RKE2 worker nodes.

Issue 80:
Deploy and troubleshoot Kubernetes workloads.

## DevOps and SRE Relevance

This architecture demonstrates:

- Kubernetes control-plane design
- Worker-node lifecycle management
- Cluster networking
- Secure node registration
- Infrastructure separation
- High-availability concepts
- etcd quorum understanding
- Container runtime architecture
- Workload migration
- Operational troubleshooting
- Production architecture planning
