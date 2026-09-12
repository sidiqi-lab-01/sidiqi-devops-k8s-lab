# Ansible Playbooks, Roles and Handlers

## Purpose

Issue #71 implements reusable Ansible automation for Linux configuration using playbooks, roles, variables, templates, handlers, packages, services, users and files.

## Environment

Control node:
- Ubuntu 24.04
- Ansible control environment
- GitHub repository: sidiqi-devops-k8s-lab

Managed node:
- Host: ansible-managed-01
- Private IP: 172.31.22.252
- OS: Ubuntu 24.04.4 LTS
- SSH user: ubuntu

## Architecture

The playbook targets the managed inventory group and applies the reusable web_server role.

Components:

- playbooks/configure-web-server.yml
- roles/web_server/defaults/main.yml
- roles/web_server/tasks/main.yml
- roles/web_server/handlers/main.yml
- roles/web_server/templates/index.html.j2

## Role Capabilities

The web_server role:

- installs nginx
- creates and manages the web root
- deploys a Jinja2-generated web page
- enables and starts nginx
- reloads nginx through a handler when the template changes
- creates the devopsapp Linux user
- deploys /etc/devops-lab.conf
- uses role defaults instead of hard-coded values

## Variables

Role variables include:

- web_server_package
- web_server_service
- web_server_root
- web_server_index
- web_server_title
- web_server_environment
- web_server_owner
- web_server_group
- managed_user_name
- managed_user_shell
- managed_file_path

## Handler Behavior

The template task notifies the nginx reload handler only when rendered content changes.

A variable change from development to production caused the template to change and triggered the handler.

A following unchanged run did not execute the handler.

## Initial Deployment

Before deployment:

- nginx was not installed
- nginx service did not exist
- /var/www/html did not exist
- TCP port 80 was not listening

The first real playbook execution completed successfully.

Result:

- nginx installed
- web root created
- template deployed
- nginx enabled and active
- nginx handler executed
- HTTP locally returned status 200

Play recap:

ok=6
changed=4
unreachable=0
failed=0

## User and File Management

The role was extended to create:

User:
- devopsapp
- home: /home/devopsapp
- shell: /bin/bash

Managed file:
- /etc/devops-lab.conf

Example content:

managed_by=ansible
role=web_server
environment=production
host=ansible-managed-01

The first run after adding these resources reported two changes.

The following run reported:

ok=7
changed=0
unreachable=0
failed=0

This demonstrates idempotency.

## Troubleshooting Scenario 1 - Check Mode

Ansible check mode simulated nginx installation but did not actually install the package.

The later service task failed because systemd could not find nginx.

Error:

Could not find the requested service nginx: host

This demonstrated an important check-mode limitation: later tasks may depend on resources that an earlier task only simulated creating.

The actual playbook run completed successfully.

## Troubleshooting Scenario 2 - HTTP Connectivity

HTTP worked locally on the managed node:

- nginx active
- TCP/80 listening
- HTTP status 200

HTTP from the Ansible control node initially failed.

The managed EC2 Security Group allowed TCP/22 but did not initially allow TCP/80.

This isolated the failure to network policy rather than nginx or Ansible.

A least-privilege Security Group rule was used to allow HTTP connectivity from the control-node Security Group instead of exposing port 80 broadly.

## Idempotency

Repeated executions converge to the same desired state.

Final validation:

ok=7
changed=0
unreachable=0
failed=0

No unnecessary configuration changes occurred.

## Production Relevance

This pattern applies directly to production DevOps and SRE environments.

Reusable roles can standardize:

- operating system configuration
- package installation
- services
- application users
- configuration files
- templates
- handlers
- environment-specific variables

Idempotency makes configuration predictable and repeatable across fleets of servers.

Handlers prevent unnecessary service reloads or restarts.

## Interview Explanation

I built a reusable Ansible role that configures a Linux web server from a clean Ubuntu host. The role installs and manages nginx, creates users and files, deploys Jinja2 templates, manages services and uses handlers so nginx only reloads when configuration changes.

I validated the role through syntax checks, a first deployment, HTTP testing and repeated runs. The second run returned changed=0, which demonstrated idempotency.

I also tested troubleshooting scenarios. Check mode exposed a dependency limitation because nginx was only simulated as installed, and an HTTP connectivity issue was isolated to the AWS Security Group after verifying nginx and port 80 were healthy locally.

This gives me a repeatable pattern I can apply to larger Linux fleets and production automation.

## Issue #71 Completion Evidence

- [x] Implementation completed
- [x] Validation completed
- [x] Troubleshooting scenarios tested
- [x] Documentation created
- [x] Automation created
- [ ] Pull request reviewed and merged
