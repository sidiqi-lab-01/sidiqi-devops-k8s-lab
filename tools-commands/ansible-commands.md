# Ansible Command Reference

## Version

Command:

    ansible --version

Usage:
Displays the installed Ansible version, Python version, configuration file,
module paths, and collection locations.

## Inventory Graph

Command:

    ansible-inventory -i inventory/hosts.ini --graph

Usage:
Displays Ansible inventory groups and managed hosts.

## Inventory Details

Command:

    ansible-inventory -i inventory/hosts.ini --list

Usage:
Shows the fully parsed inventory including variables.

## Connectivity Test

Command:

    ansible all -i inventory/hosts.ini -m ping

Usage:
Tests SSH connectivity and verifies that Ansible can execute Python on
managed hosts.

## Ad-Hoc Command

Command:

    ansible all -i inventory/hosts.ini -a "hostname"

Usage:
Runs a one-time command against managed hosts without creating a playbook.

## Gather Facts

Command:

    ansible all -i inventory/hosts.ini -m setup

Usage:
Collects operating system, networking, CPU, memory, and other facts from
managed hosts.

## Run Playbook

Command:

    ansible-playbook -i inventory/hosts.ini site.yml

Usage:
Executes an Ansible playbook against the specified inventory.

## Syntax Check

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --syntax-check

Usage:
Checks playbook syntax without applying configuration.

## Check Mode

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --check

Usage:
Performs a dry-run style execution and predicts changes where supported.

## Check Mode With Diff

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --check --diff

Usage:
Shows proposed configuration-file changes without applying them.

## Limit Hosts

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --limit webservers

Usage:
Runs a playbook only against a selected host or inventory group.

## Run Tags

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --tags nginx

Usage:
Executes only tasks associated with the specified tag.

## List Tasks

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --list-tasks

Usage:
Displays the tasks that would be executed.

## List Tags

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --list-tags

Usage:
Shows available playbook tags.

## Privilege Escalation

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --become

Usage:
Runs tasks requiring sudo/root privileges through Ansible privilege
escalation.

## Vault Encrypt

Command:

    ansible-vault encrypt inventory/group_vars/all/vault.yml

Usage:
Encrypts sensitive Ansible variables.

## Vault View

Command:

    ansible-vault view inventory/group_vars/all/vault.yml

Usage:
Decrypts and displays a Vault-protected file after authentication.

## Vault Edit

Command:

    ansible-vault edit inventory/group_vars/all/vault.yml

Usage:
Safely edits an encrypted Vault file.

## Run Playbook With Vault

Command:

    ansible-playbook -i inventory/hosts.ini site.yml --ask-vault-pass

Usage:
Prompts for the Vault password before executing the playbook.

## Idempotency Test

Commands:

    ansible-playbook -i inventory/hosts.ini site.yml
    ansible-playbook -i inventory/hosts.ini site.yml

Usage:
Runs the same configuration twice. The second execution should ideally
report changed=0 and failed=0, demonstrating idempotency.
