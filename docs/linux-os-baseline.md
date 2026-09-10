# Linux Operating System Baseline

## Overview

This document records the Linux operating-system baseline for the DevOps lab administration host.

The baseline establishes the current OS, kernel, CPU, memory, storage, filesystem, virtualization, hostname, and system-load characteristics.

## Operating System

- Distribution: Ubuntu
- Version: Ubuntu 24.04.4 LTS
- Version ID: `24.04`
- Codename: `noble`
- Architecture: `x86_64`

## Kernel

- Kernel: `Linux 6.17.0-1017-aws`
- Kernel architecture: `x86_64`
- AWS-specific kernel is running on the EC2 administration host.

## Host and Virtualization

- Hostname: `ip-172-31-16-171`
- Hardware vendor: Amazon EC2
- Hardware model: `t3.small`
- Virtualization platform: Amazon EC2
- Hypervisor: KVM
- Virtualization type: Full virtualization

## Uptime and Load

The baseline was collected with:

```bash
uptime
Observed:

up 1 day, 11:11
2 users
load average: 0.00, 0.00, 0.00

The host was operating with negligible CPU load at the time of collection.

CPU

The system reports:

Architecture: x86_64
CPUs: 2
Online CPUs: 0,1
CPU vendor: Intel
CPU model: Intel Xeon Platinum 8259CL @ 2.50GHz
Cores per socket: 1
Threads per core: 2
Sockets: 1
NUMA nodes: 1

This represents two virtual CPUs exposed to the EC2 instance.

Memory

Observed memory baseline:

Total:       1.9 GiB
Used:        448 MiB
Free:        446 MiB
Buff/cache:  1.2 GiB
Available:   1.4 GiB
Swap:        0 B

The host currently has no configured swap space.

Block Devices

The primary storage device is:

nvme0n1       30G  disk
├─nvme0n1p1   29G  part /
├─nvme0n1p14   4M  part
├─nvme0n1p15 106M  part /boot/efi
└─nvme0n1p16 913M  part /boot

Several loop devices are also present for Snap packages, including the Amazon SSM Agent.

Filesystem Utilization

Observed filesystem utilization:

Filesystem	Size	Used	Available	Use	Mount
/dev/root	29G	4.2G	24G	15%	/
/dev/nvme0n1p16	881M	183M	637M	23%	/boot
/dev/nvme0n1p15	105M	6.2M	99M	6%	/boot/efi

The root filesystem has substantial available capacity at the time of baseline collection.

Baseline Commands

The following commands were executed successfully:

uname -a
cat /etc/os-release
hostnamectl
uptime
lscpu
free -h
lsblk
df -h
Troubleshooting Workflow

These commands provide a practical first-step Linux troubleshooting workflow:

Operating System
      |
      v
uname -a / os-release
      |
      v
Host and Virtualization
      |
      v
hostnamectl
      |
      v
System Health
      |
      +----> uptime
      |
      +----> free -h
      |
      +----> lscpu
      |
      v
Storage
      |
      +----> lsblk
      |
      +----> df -h
Administration Notes

For Linux administration and troubleshooting, the baseline should be re-collected after significant system changes such as:

Kernel upgrades
OS upgrades
Storage expansion
Application deployments
Kubernetes installation
Major networking changes
Performance incidents

The baseline provides a reference point for identifying changes in CPU, memory, disk, filesystem, and system health.

Interview Relevance

This baseline demonstrates practical Linux administration skills, including:

Identifying the Linux distribution and kernel
Understanding x86-64 architecture
Inspecting CPU and memory resources
Understanding virtualized EC2 environments
Checking system uptime and load
Inspecting disks and partitions
Checking filesystem capacity
Establishing first-step troubleshooting procedures
Validation Status
 Linux commands executed successfully
 Results reviewed
 OS and kernel identified
 CPU and memory inspected
 Storage and filesystem inspected
 Linux baseline documented
 Git changes committed and pushed
 Pull request reviewed
