# Linux Package Management and Software Installation

## Overview

This lab demonstrates Ubuntu Linux package management using APT and dpkg.
The objective is to establish a repeatable and verifiable software
installation workflow that can later be automated with configuration
management and Infrastructure as Code.

The lab was performed on Ubuntu 24.04.4 LTS.

## Package Management Tools

The primary package management tools used are:

- `apt` - high-level package management
- `apt-cache` - repository and package metadata
- `dpkg` - Debian package database and package inspection
- `dpkg-query` - package version queries

APT version:

```text
apt 2.8.3 (amd64)

Inspecting Available Updates

The following command identifies packages with available updates:

apt list --upgradable

The system reported 13 available package updates, including Ubuntu system
packages and Terraform.

Terraform was reported as:

terraform/noble 1.16.2-1 amd64
upgradable from: 1.16.1-1

The available updates were intentionally not applied as part of this lab.
Identifying updates and actually installing them are separate operational
activities.

APT Repository Inspection

Repository and package policy information can be inspected with:

apt-cache policy

The system uses Ubuntu Noble repositories including:

Noble
Noble Updates
Noble Security
Noble Backports

A HashiCorp repository is also configured for Terraform.

During apt update, Ubuntu repository metadata was successfully retrieved.
The HashiCorp repository returned a GPG signature verification warning:

NO_PUBKEY FC9CA96ACA026560

APT therefore did not refresh the HashiCorp repository index and retained
the previously available index.

This is an important security behavior. Repository signature verification
should not be bypassed merely to make an update succeed. The repository
key should be validated and installed through an approved process before
trusting new package metadata.

Refreshing the Package Index

The package index was refreshed with:

sudo apt update

APT successfully updated the Ubuntu repository metadata.

The HashiCorp repository generated a signature verification warning because
its required public key was not available.

No insecure apt options were used to bypass the signature verification.

Inspecting Installed Packages

Installed packages can be inspected with:

dpkg -l

Specific packages can be inspected with:

dpkg -l net-tools dnsutils traceroute

The ii status indicates that the package is installed and configured.

Installing Networking Tools

The following networking packages were required for upcoming Linux
networking exercises:

sudo apt install -y net-tools dnsutils traceroute

The final installed package versions were:

dnsutils    1:9.18.39-0ubuntu0.24.04.7
net-tools   2.10-0.1ubuntu4.4
traceroute  1:2.1.5-1

net-tools and dnsutils were already installed at the current candidate
versions. traceroute was newly installed.

Verifying Installed Packages

Package installation was verified with:

dpkg -l net-tools dnsutils traceroute

The resulting state was:

ii  dnsutils
ii  net-tools
ii  traceroute

All three packages are installed and configured successfully.

Package Version Verification

APT package policy was checked with:

apt-cache policy net-tools dnsutils traceroute

The installed and candidate versions were:

net-tools
Installed: 2.10-0.1ubuntu4.4
Candidate: 2.10-0.1ubuntu4.4

dnsutils
Installed: 1:9.18.39-0ubuntu0.24.04.7
Candidate: 1:9.18.39-0ubuntu0.24.04.7

traceroute
Installed: 1:2.1.5-1
Candidate: 1:2.1.5-1

This confirms that each required networking package is installed at the
current APT candidate version.

Verifying Commands

The installed packages provide the following commands:

ifconfig: /usr/sbin/ifconfig
netstat: /usr/bin/netstat
dig: /usr/bin/dig
nslookup: /usr/bin/nslookup
host: /usr/bin/host
traceroute: /usr/sbin/traceroute

These commands will be used in subsequent networking exercises.

Networking Tool Mapping
Package	Commands	Purpose
net-tools	ifconfig, netstat	Interface and legacy network inspection
dnsutils	dig, nslookup, host	DNS troubleshooting
traceroute	traceroute	Network path analysis

Modern Linux systems commonly use ip and ss, but ifconfig and netstat
remain useful when working with legacy systems and troubleshooting existing
environments.

Command Version Verification

The installed tools reported:

net-tools 2.10
DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu
Modern traceroute for Linux, version 2.1.5

The version information provides an additional validation layer beyond
checking only whether the command exists.

Package Database Verification

Installed package versions were also queried directly:

dpkg-query -W -f='${Package} ${Version}\n' net-tools dnsutils traceroute

Result:

dnsutils 1:9.18.39-0ubuntu0.24.04.7
net-tools 2.10-0.1ubuntu4.4
traceroute 1:2.1.5-1

This provides a machine-readable record that can be used by automation or
configuration-management workflows.

Safe Package Removal

Before removing software, APT can simulate the operation:

sudo apt remove --simulate traceroute

The simulation reported:

The following packages will be REMOVED:
  traceroute

0 upgraded, 0 newly installed, 1 to remove

No package was actually removed.

The package was then verified again:

dpkg -l net-tools dnsutils traceroute

traceroute remained installed.

This demonstrates a safe operational workflow:

Identify the package.
Simulate the removal.
Review the proposed changes.
Check dependencies and operational impact.
Perform the actual removal only after approval.
Reproducible Software Installation

For production infrastructure, software installation should be repeatable
rather than dependent on undocumented manual commands.

Recommended practices include:

Define required packages explicitly.
Use automation for repeatable installations.
Verify package installation.
Record package versions when exact reproducibility is required.
Validate repository sources and signing keys.
Test package updates before production deployment.
Avoid unnecessary software installations.
Keep system configuration documented.

Example Ansible configuration:

- name: Install networking utilities
  ansible.builtin.apt:
    name:
      - net-tools
      - dnsutils
      - traceroute
    state: present
    update_cache: true

This allows the same package requirements to be applied consistently across
multiple Linux systems.

Relationship to Terraform and Infrastructure as Code

Terraform provisions infrastructure such as AWS networking and EC2
instances.

Configuration-management tools such as Ansible or cloud-init can then
configure the operating system and install required software.

A typical workflow is:

Terraform
    |
    +-- AWS VPC
    +-- Subnets
    +-- Security Groups
    +-- EC2
          |
          +-- Ubuntu Linux
                |
                +-- Ansible / cloud-init
                      |
                      +-- Required packages

This separates infrastructure provisioning from operating-system
configuration.

Operational Troubleshooting Workflow

A practical package-management workflow is:

1. Identify required software
        |
2. Inspect configured repositories
        |
3. Refresh package metadata
        |
4. Check available versions
        |
5. Install required packages
        |
6. Verify package state
        |
7. Verify commands
        |
8. Record versions
        |
9. Automate the configuration

Useful commands include:

apt-cache policy <package>
apt list --upgradable
dpkg -l <package>
dpkg-query -W -f='${Package} ${Version}\n' <package>
command -v <command>
Security Considerations

APT repository signatures provide a trust mechanism for package metadata.

If a repository reports a missing public key or signature verification
failure, the correct response is to investigate and validate the repository
configuration and signing key.

Do not disable GPG verification or use insecure repository options simply to
force an installation or update.

This is particularly important in production, regulated, and classified
environments where software provenance and integrity are critical.

Lab Completion
 APT package management workflow demonstrated.
 APT repository configuration inspected.
 Available package updates inspected.
 Installed packages inspected with dpkg.
 Required networking tools installed.
 Package versions verified.
 Installed commands verified.
 Safe package removal simulation demonstrated.
 Packages confirmed to remain installed.
 Reproducible installation practices documented.
 Repository signature verification behavior documented.
 Relationship to Ansible and Terraform documented.
Key Takeaway

Linux package management is a fundamental part of reliable infrastructure
operations.

The production goal is not simply to install software once. The goal is to
define, automate, verify, and reproduce the required software state across
systems.

This exercise directly supports the upcoming Linux networking labs and
provides practical experience applicable to Ansible, Terraform, AWS EC2,
Kubernetes node administration, and DevOps automation.
