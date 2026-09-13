# RKE2 Kubernetes Lab

This directory contains reusable architecture and configuration artifacts for
the RKE2 Kubernetes milestone.

## Planned Lab Topology

    DevOps Admin EC2
          |
          | SSH / Ansible / kubectl
          |
    RKE2 Server 01
          |
       +--+--+
       |     |
    Worker1 Worker2

## Node Naming

Planned node names:

    rke2-server-01
    rke2-worker-01
    rke2-worker-02

## Configuration

Server example:

    config/server-config.yaml.example

Worker example:

    config/agent-config.yaml.example

The example files intentionally contain placeholders.

Real registration tokens, credentials, certificates, and other sensitive
values must not be committed to Git.

## Implementation Sequence

Issue 77:
Architecture and configuration design.

Issue 78:
Install and validate the RKE2 server.

Issue 79:
Create and join worker nodes.

Issue 80:
Deploy and troubleshoot Kubernetes workloads.

## Management Model

The existing DevOps admin EC2 remains outside the Kubernetes cluster.

It will be used for:

- Git operations
- AWS CLI
- Ansible
- kubectl
- cluster administration
- troubleshooting

This separation protects management tooling from Kubernetes workload and
control-plane experiments.
