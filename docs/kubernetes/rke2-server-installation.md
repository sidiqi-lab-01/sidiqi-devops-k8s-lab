# RKE2 Server Installation and Validation

## Overview

This document records the installation and validation of the first RKE2 Kubernetes server for the DevOps lab.

## Server

- Name: rke2-server-01
- Cloud: AWS
- Region: us-east-2
- Availability Zone: us-east-2b
- Instance Type: m7i-flex.large
- OS: Ubuntu 24.04 LTS
- Private IP: 172.31.29.36
- Container Runtime: containerd
- RKE2 Version: v1.36.4+rke2r1

## AWS Architecture

The RKE2 server runs in the same VPC as the DevOps administration node.

Management access is restricted through AWS security-group references.

RKE2 cluster security group:

- SSH TCP 22 from DevOps admin security group
- Kubernetes API TCP 6443 from RKE2 cluster members
- Kubernetes API TCP 6443 from DevOps admin
- RKE2 supervisor TCP 9345 from cluster members
- kubelet TCP 10250 from cluster members
- embedded etcd TCP 2379-2381 from cluster members
- Canal VXLAN UDP 8472 from cluster members
- Canal health TCP 9099 from cluster members

Internal Kubernetes networking ports are not exposed publicly.

## RKE2 Configuration

RKE2 server configuration is stored at:

    /etc/rancher/rke2/config.yaml

Configured values include:

- Node name: rke2-server-01
- Pod CIDR: 10.42.0.0/16
- Service CIDR: 10.43.0.0/16
- Environment and node-role labels

## Installation

RKE2 was installed using the official installation script.

The installed version was:

    v1.36.4+rke2r1

The server service was enabled and started using systemd.

## Control Plane Validation

The following control-plane components were verified:

- Kubernetes API server
- Kubernetes controller manager
- Kubernetes scheduler
- embedded etcd
- kube-proxy
- RKE2 Canal CNI
- CoreDNS
- metrics-server
- snapshot controller
- Traefik

The node reached:

    Ready

with the roles:

    control-plane,etcd

## Kubernetes DNS Validation

A temporary BusyBox pod was used to verify internal Kubernetes DNS.

The test resolved:

    kubernetes.default.svc.cluster.local

to:

    10.43.0.1

using CoreDNS:

    10.43.0.10

The temporary test pod was removed after validation.

## Remote Administration

kubectl v1.36.4 was installed on the DevOps administration EC2 instance.

The RKE2 kubeconfig was securely retrieved from:

    /etc/rancher/rke2/rke2.yaml

The API endpoint was updated from:

    https://127.0.0.1:6443

to:

    https://172.31.29.36:6443

Remote administration was successfully validated with:

    kubectl get nodes -o wide

and:

    kubectl get pods -A

This allows Kubernetes administration from the dedicated DevOps management node without requiring interactive SSH access to the RKE2 control-plane node.

## Security

The RKE2 registration token exists at:

    /var/lib/rancher/rke2/server/node-token

The token is not stored in Git.

The kubeconfig is protected with file permissions:

    0600

Internal Kubernetes and RKE2 ports are restricted using security-group-to-security-group rules.

## Result

The RKE2 Kubernetes server is successfully installed, running, and remotely manageable from the DevOps administration node.

Issue #78 objectives are satisfied:

- RKE2 server deployed
- Kubernetes API validated
- system pods validated
- node health validated
- cluster networking validated
- DNS validated
- container runtime validated
- secure remote administration validated
