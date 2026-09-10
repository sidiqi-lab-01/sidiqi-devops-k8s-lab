# Linux Processes, Services and Systemd

## Overview

This lab demonstrates Linux process inspection, systemd service management, resource monitoring, service logging, dependency analysis, and basic troubleshooting.

These skills are important for troubleshooting Kubernetes nodes, CI/CD servers, application servers, container hosts, and infrastructure automation environments.

## Process Inspection

Commands used:

```bash
ps aux
pstree -p '''
The ps aux command was used to inspect running Linux processes.

Key observations:

PID 1 is systemd.
sshd manages SSH connections and creates child processes for user sessions.
amazon-ssm-agent runs AWS Systems Manager processes.
systemd-journald manages system journal logging.
systemd-networkd manages network configuration.
systemd-resolved provides DNS resolution.
systemd-udevd manages device events.
rsyslogd provides system logging.
cron manages scheduled tasks.
Kernel worker processes such as kworker perform background kernel operations.

The pstree -p command demonstrated parent/child process relationships.

Resource Monitoring

Command used:

top

Observed:

114 total tasks
1 running process
113 sleeping processes
0 stopped processes
0 zombie processes
Approximately 100% CPU idle
Load average approximately 0.00, 0.00, 0.00
Approximately 1.9 GiB RAM
Approximately 1.46 GiB available memory
No swap configured

The system was healthy and under very low resource utilization.

top is useful for identifying CPU exhaustion, memory exhaustion, high system load, and abnormal processes.

Systemd Services

Command used:

systemctl list-units --type=service

Examples of active services included:

ssh.service
systemd-journald.service
systemd-networkd.service
systemd-resolved.service
chrony.service
rsyslog.service
snap.amazon-ssm-agent.amazon-ssm-agent.service
cron.service
dbus.service
multipathd.service

systemd provides centralized management for Linux services.

SSH Service Inspection

Command used:

systemctl status ssh

The SSH service was confirmed to be:

Loaded
Active
Running
Managed by systemd
Listening on TCP port 22
Associated with ssh.socket
Configured with an EC2 Instance Connect drop-in

The service status also showed the main PID, memory usage, CPU usage, start time, CGroup, unit file, and drop-in configuration.

Service Logs

Command used:

sudo journalctl -u ssh

The system journal showed:

SSH service startup
SSH listening on IPv4 and IPv6
Successful public-key authentication
SSH sessions being opened
A previous SSH service termination
Subsequent SSH service restart

The first non-privileged journalctl -u ssh command did not provide the expected system-level journal entries because the user did not have sufficient access to the system journal. Using sudo provided access.

Systemd Unit Configuration

Command used:

systemctl cat ssh

The SSH service unit was located at:

/usr/lib/systemd/system/ssh.service

An EC2 Instance Connect drop-in was also present:

/usr/lib/systemd/system/ssh.service.d/ec2-instance-connect.conf

The SSH service configuration included:

ExecStartPre=/usr/sbin/sshd -t
ExecStart=/usr/sbin/sshd -D
Restart=on-failure
Type=notify

The EC2 Instance Connect drop-in modifies the SSH startup configuration to support EC2 Instance Connect key authorization.

Systemd Configuration Troubleshooting

systemctl status ssh initially reported that the service unit configuration had changed on disk.

The systemd configuration was reloaded with:

sudo systemctl daemon-reload

The service was then verified with:

systemctl status ssh --no-pager

The warning was no longer present and SSH remained active.

Important distinction
sudo systemctl daemon-reload

causes systemd to reread unit files and drop-ins.

It does not restart the service.

A restart is performed with:

sudo systemctl restart ssh
Failed Services

Command used:

systemctl --failed

Result:

0 loaded units listed.

No systemd services were in a failed state.

Service Dependencies

Command used:

systemctl list-dependencies ssh

This displayed dependencies associated with:

System initialization
Filesystems
Networking
Logging
SSH socket activation
System slices
Other systemd-managed components

Understanding dependencies is important when a service fails because the root cause may be another service or system component.

Common systemctl Commands

Check status:

systemctl status <service>

Start:

sudo systemctl start <service>

Stop:

sudo systemctl stop <service>

Restart:

sudo systemctl restart <service>

Reload:

sudo systemctl reload <service>

Enable at boot:

sudo systemctl enable <service>

Disable at boot:

sudo systemctl disable <service>

Check whether enabled:

systemctl is-enabled <service>

Check whether active:

systemctl is-active <service>

List services:

systemctl list-units --type=service

List failed services:

systemctl --failed

View unit configuration:

systemctl cat <service>

View service logs:

sudo journalctl -u <service>

Follow service logs:

sudo journalctl -u <service> -f

View recent service logs:

sudo journalctl -u <service> --since "1 hour ago"
Troubleshooting Workflow

A practical Linux service troubleshooting workflow is:

Check service status.
Review service logs.
Inspect the systemd unit and drop-ins.
Check dependencies.
Check CPU, memory, and disk resources.
Check for failed services.
Reload systemd if unit files changed.
Correct the underlying problem.
Restart the service when necessary.
Verify the service and logs after remediation.

Typical commands:

systemctl status <service>
sudo journalctl -u <service>
systemctl cat <service>
systemctl list-dependencies <service>
top
free -h
df -h
systemctl --failed
sudo systemctl daemon-reload
systemctl status <service>
SSH Configuration Validation

For SSH, configuration can be validated before restarting the service:

sudo sshd -t

If the command returns no output, the SSH configuration passed the syntax test.

This is safer than blindly restarting SSH after changing configuration.

Kubernetes and DevOps Relevance

Linux process and systemd knowledge is directly relevant to Kubernetes operations.

Kubernetes nodes depend on Linux host services such as:

kubelet
Container runtime
Networking services
DNS services
Logging agents
Monitoring agents
Storage services
SSH
Operating-system services

A Kubernetes node problem may originate below Kubernetes itself.

For example:

Kubernetes problem
        |
        +-- kubelet failure
        |
        +-- container runtime failure
        |
        +-- networking failure
        |
        +-- disk exhaustion
        |
        +-- memory exhaustion
        |
        +-- CPU exhaustion
        |
        +-- systemd service failure
        |
        +-- operating-system problem

Therefore, Kubernetes troubleshooting should include both Kubernetes-level and Linux host-level investigation.

CI/CD Relevance

CI/CD infrastructure also depends on Linux services and processes.

Examples include:

Jenkins
GitHub Actions runners
GitLab runners
Container services
Terraform execution environments
Ansible automation
Monitoring agents
Artifact services

If a CI/CD runner stops working, the engineer can investigate:

systemctl status <service>
sudo journalctl -u <service>
top
free -h
df -h
systemctl --failed

This helps determine whether the problem is application-related, resource-related, or operating-system-related.

Infrastructure Automation Relevance

These Linux troubleshooting skills can be automated using:

Terraform
Ansible
Bash
Python
CI/CD pipelines

For example, Ansible can ensure a required service is running:

- name: Ensure SSH service is running
  ansible.builtin.service:
    name: ssh
    state: started
    enabled: true

Terraform can provision infrastructure while Ansible can configure operating-system services.

This creates a common DevOps workflow:

Terraform
    |
    v
AWS Infrastructure
    |
    v
Linux Operating System
    |
    v
Ansible / systemd
    |
    v
Applications and Services
Lab Completion
Running Linux processes inspected
Parent/child process relationships inspected
CPU and memory utilization inspected
Systemd services listed
SSH service inspected
SSH service logs reviewed
Systemd unit configuration inspected
EC2 Instance Connect drop-in identified
Systemd configuration reloaded
Failed services checked
SSH dependencies inspected
Linux troubleshooting workflow documented
Kubernetes and DevOps relevance documented
