# Linux Filesystems, Disk and Storage Administration

## Overview

This document records the Linux filesystem, disk, mount, and storage investigation performed on the AWS EC2 lab host.

The purpose is to understand Linux block devices, partitions, filesystem types, mounted filesystems, disk utilization, inode utilization, and practical storage troubleshooting.

These concepts directly support AWS EBS, NFS, Rook/Ceph, Kubernetes persistent storage, and production troubleshooting.

## Storage Layout

The lab host uses a 30 GB NVMe root disk.

### Block Devices

Command:

```bash
lsblk ```

### Observed storage layout:

nvme0n1 - 30G primary disk
nvme0n1p1 - 29G ext4 root filesystem mounted at /
nvme0n1p14 - 4M partition
nvme0n1p15 - 106M VFAT EFI partition mounted at /boot/efi
nvme0n1p16 - 913M ext4 boot filesystem mounted at /boot

The system also contains Snap loop devices using SquashFS filesystems.

Detailed Block Device Information

Command:

lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

The command confirms the relationship between:

Physical or virtual block devices
Partitions
Filesystem types
Mount points

The main storage path is:

nvme0n1
├── nvme0n1p1   ext4   /
├── nvme0n1p14
├── nvme0n1p15   vfat   /boot/efi
└── nvme0n1p16   ext4   /boot
Filesystem Utilization

Command:

df -h

Root filesystem utilization:

Filesystem      Size  Used  Avail  Use%
/dev/root        29G  4.2G   24G   15%

The root filesystem is currently healthy with approximately 15% capacity utilization.

Filesystem Types

Command:

df -Th

Observed filesystems include:

Root filesystem: ext4
/boot: ext4
/boot/efi: vfat
Temporary filesystems: tmpfs
Snap images: squashfs

The ext4 filesystem provides the primary Linux storage for the operating system and user data.

Mounted Filesystems

Command:

mount

The mount command displays active filesystem mounts and their associated mount options.

Important mounts include:

/ mounted from /dev/nvme0n1p1
/boot mounted from /dev/nvme0n1p16
/boot/efi mounted from /dev/nvme0n1p15
Snap packages mounted as read-only SquashFS loop devices
findmnt Investigation

Command:

findmnt

The command provides a structured view of the filesystem hierarchy.

The root filesystem is:

Source: /dev/nvme0n1p1
Filesystem: ext4
Mount point: /

Root filesystem mount options include:

rw,relatime,discard,errors=remount-ro,commit=30

The errors=remount-ro option provides protection by remounting the filesystem read-only if certain filesystem errors occur.

The discard option enables filesystem-level discard/TRIM behavior for supported underlying storage.

Root Filesystem Verification

Command:

df -h /

Observed:

Size: 29G
Used: 4.2G
Available: 24G
Usage: 15%

The system is not currently experiencing root filesystem capacity pressure.

Inode Utilization

Command:

df -i

Observed root filesystem inode utilization:

Total inodes: 3,801,088
Used:         140,091
Free:       3,660,997
Usage:              4%

Inode utilization is only approximately 4%.

This is important because a Linux filesystem can run out of inodes even when free disk space remains.

Example troubleshooting scenario:

df -h

may show available disk space while:

df -i

shows 100% inode utilization.

This can happen when a system contains a very large number of small files.

Home Directory Usage

Command:

du -sh ~

Observed:

/home/sidiqi    854M

This identifies the amount of storage consumed by the current user's home directory.

Root-Level Disk Usage

Command:

sudo du -xhd1 / | sort -h

Observed major consumers:

/usr      2.4G
/home     1.2G
/var      657M
/         4.2G

The /usr directory is the largest major filesystem consumer.

The /home directory is the second-largest major consumer and contains user data.

The /var directory contains application state, package caches, logs, and other variable system data.

/var Storage Investigation

Command:

sudo du -xhd1 /var | sort -h

Observed:

/var/lib      476M
/var/cache    154M
/var/log       27M
/var          657M

The largest portion of /var is /var/lib.

Package caches and Snap data account for a significant portion of the storage usage.

Largest Files Under /var

Command:

sudo find /var -xdev -type f -printf '%s %p\n' | sort -n | tail -20

Examples of large files observed include:

Snap package images
APT package indexes
APT package cache files
Snap cache files
Firmware update metadata

This is a useful production troubleshooting technique when /var grows unexpectedly.

Open Deleted Files

Command:

sudo lsof +L1 | head -30

The command identified processes holding deleted files open.

Examples included system processes holding deleted Python and systemd-related files.

This demonstrates an important Linux storage troubleshooting scenario:

A process opens a file.
The file is deleted.
The process continues running.
Disk space can remain allocated until the process closes the file.

Therefore, deleting a large file does not always immediately recover disk space.

A common investigation workflow is:

df -h
sudo lsof +L1

If df reports high utilization but normal directory sizes do not explain it, open deleted files are one possible cause.

Storage Troubleshooting Workflow

A practical Linux disk troubleshooting workflow is:

1. Check filesystem capacity
df -h
2. Check filesystem types
df -Th
3. Check inode utilization
df -i
4. Inspect block devices
lsblk
5. Inspect mounts
findmnt
mount
6. Identify large directories
sudo du -xhd1 / | sort -h
7. Investigate large files
sudo find /var -xdev -type f -printf '%s %p\n' | sort -n | tail -20
8. Investigate deleted files still held open
sudo lsof +L1

This workflow separates common storage problems into capacity, inode, filesystem, mount, directory, file, and open-deleted-file categories.

AWS EBS Relationship

In AWS, EC2 instances use block storage volumes such as Amazon EBS.

A simplified relationship is:

AWS EBS Volume
      |
      v
EC2 Block Device
      |
      v
Linux Disk
      |
      v
Partition
      |
      v
Filesystem
      |
      v
Mount Point

For example, the lab host's Linux root storage appears as an NVMe block device:

nvme0n1

with the primary root partition:

nvme0n1p1

mounted as:

/

In AWS environments, an EBS volume can be attached to an EC2 instance and then exposed to Linux as a block device.

Administrators may then:

Identify the device.
Partition it if required.
Create a filesystem.
Mount it.
Configure persistent mounting.
Monitor capacity and performance.
Kubernetes Persistent Storage Relationship

Kubernetes abstracts storage through several resources.

A simplified relationship is:

Application Pod
      |
      v
PersistentVolumeClaim
      |
      v
PersistentVolume
      |
      v
StorageClass / CSI Driver
      |
      v
Underlying Storage
      |
      +---- AWS EBS
      +---- NFS
      +---- Rook/Ceph
      +---- Other storage systems
PersistentVolumeClaim

A Pod normally requests storage using a PersistentVolumeClaim (PVC).

Example:

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: application-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

The PVC represents the application's request for persistent storage.

PersistentVolume

A PersistentVolume represents storage available to Kubernetes.

The actual implementation depends on the storage backend and CSI driver.

StorageClass

A StorageClass defines how Kubernetes dynamically provisions storage.

For cloud environments, a StorageClass can work with a CSI driver to dynamically create storage resources such as AWS EBS volumes.

AWS EBS and Kubernetes

A typical Kubernetes-on-AWS storage flow is:

Pod
 |
 | mounts PVC
 v
PersistentVolumeClaim
 |
 | binds to
 v
PersistentVolume
 |
 | provisioned by
 v
AWS EBS CSI Driver
 |
 | creates/attaches
 v
Amazon EBS Volume
 |
 v
Kubernetes Worker Node
 |
 v
Filesystem mounted into Pod

This connection is important for production Kubernetes environments because application data may need to survive Pod restarts and rescheduling.

NFS Relationship

NFS provides network-based filesystem storage.

Unlike an individual block device, NFS allows clients to access files over the network.

Typical architecture:

Kubernetes Pod
      |
      v
PVC
      |
      v
PV / CSI or NFS configuration
      |
      v
NFS Server
      |
      v
Shared Filesystem

NFS can be useful when multiple workloads need shared file access.

Rook/Ceph Relationship

Rook is a Kubernetes operator commonly used to manage Ceph storage.

A simplified architecture is:

Kubernetes
    |
    v
Rook Operator
    |
    v
Ceph Cluster
    |
    +---- Block Storage
    +---- Shared Filesystem
    +---- Object Storage

Ceph can provide distributed storage across multiple nodes and is useful for environments requiring scalable and resilient storage.

Production Storage Considerations

When troubleshooting production storage, consider:

Filesystem capacity
Inode utilization
Large directories
Large individual files
Application logs
Package caches
Container images
Container writable layers
Deleted files held open
Mount failures
Incorrect mount points
Filesystem errors
EBS volume capacity
EBS performance characteristics
Kubernetes PVC capacity
StorageClass configuration
CSI driver health
Pod volume mounts
Node-level storage pressure
Kubernetes Node Storage Pressure

Kubernetes nodes monitor local storage resources.

Storage pressure can affect:

Pod scheduling
Container image management
Pod eviction
Logs
Temporary files
Container writable layers

A Kubernetes administrator should therefore monitor both:

Node filesystem usage

and:

Persistent application storage

These are different storage concerns.

Relevance

A strong production troubleshooting approach is to start with:

df -h
df -i
lsblk
findmnt
du -xhd1

Then determine whether the problem is:

Block-device capacity
Filesystem capacity
Inode exhaustion
Large directories
Large files
Mount problems
Deleted files still held open
Application-generated data
Kubernetes node storage pressure
Persistent volume capacity

The key principle is:

Identify the storage layer before taking corrective action.

For AWS and Kubernetes environments, this means understanding the complete path from cloud storage to the application:

EBS / NFS / Ceph
        |
        v
Linux block device or filesystem
        |
        v
Mount
        |
        v
Kubernetes node
        |
        v
PersistentVolume
        |
        v
PersistentVolumeClaim
        |
        v
Pod
        |
        v
Application
Lab Completion

Issue #32 completion criteria:

 Storage layout documented.
 Block devices inspected.
 Filesystem types identified.
 Mounted filesystems inspected.
 Disk utilization investigated.
 Inode utilization investigated.
 Directory and file usage investigated.
 Open deleted files investigated.
 Storage troubleshooting workflow documented.
 AWS EBS relationship documented.
 Kubernetes persistent storage relationship documented.
 NFS relationship documented.
 Rook/Ceph relationship documented.
Key Takeaway

Linux storage administration requires understanding the complete relationship between disks, partitions, filesystems, mounts, directories, files, and applications.

For DevOps and Kubernetes operations, these Linux fundamentals provide the foundation for troubleshooting AWS EBS volumes, Kubernetes PersistentVolumes, PersistentVolumeClaims, StorageClasses, NFS, Rook/Ceph, and node storage pressure.
