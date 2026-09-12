# Docker Container Runtime

## Objective

Issue #73 installs and validates the Docker container runtime on the Ubuntu lab control node.

The implementation establishes the container runtime foundation required for the Docker microservices and Kubernetes portions of the lab.

## Platform

- Ubuntu 24.04 LTS
- Linux on AWS EC2
- Docker Engine
- containerd
- runc
- Docker Compose
- Docker Buildx

## Architecture

The validated container execution path is:

Docker CLI
→ Docker daemon (dockerd)
→ containerd
→ runc
→ Linux container

The Docker CLI sends requests to the Docker daemon. Docker uses containerd for container lifecycle management and runc as the OCI runtime that creates the Linux container process.

Containers share the host Linux kernel while using Linux isolation mechanisms such as namespaces and cgroups.

## Runtime Validation

The installation was validated using:

- Docker client and server version checks
- Docker daemon status
- containerd service status
- Docker Compose
- Docker Buildx
- hello-world container execution
- Ubuntu container execution
- Container process inspection
- Docker network inspection
- Image inspection
- Container lifecycle operations

The hello-world test demonstrated that Docker could:

1. Contact the Docker daemon.
2. Pull an image.
3. Create a container.
4. Execute the container workload.
5. Return container output to the client.

## Container Networking

An nginx container was launched with:

-p 8080:80

This mapped TCP port 8080 on the Docker host to TCP port 80 inside the container.

HTTP connectivity was validated against:

127.0.0.1:8080

Docker inspection was used to examine the container network configuration and internal container IP address.

## Operations and Troubleshooting

Operational validation included:

- docker ps
- docker ps -a
- docker image ls
- docker network ls
- docker inspect
- docker logs
- docker rm
- systemctl status docker
- systemctl status containerd

A container troubleshooting workflow should validate:

Docker client
→ Docker daemon
→ image
→ container state
→ logs
→ process
→ network
→ port mapping
→ application

## Security

The Docker daemon normally operates with root privileges.

Users with access to the Docker daemon through the Docker Unix socket or docker group can effectively obtain root-level control of the host.

For the lab, docker group access is used for operational convenience while documenting this security implication.

Production environments should tightly control Docker daemon access and evaluate rootless containers or other security controls where appropriate.

## Result

Docker Engine and the underlying container runtime were successfully installed and validated.

The environment is ready for building the containerized microservice application in issue #74.
