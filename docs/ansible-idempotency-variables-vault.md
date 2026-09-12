# Ansible Idempotency, Variables, and Vault

## Overview

This lab validates repeatable Ansible configuration management using:

- Role defaults
- Group variables
- Host variables
- Extra variables
- Jinja2 templates
- Ansible Vault
- Secure secret deployment
- Idempotency
- Troubleshooting variable discovery and precedence

The managed host is:

- Host: ansible-managed-01
- Operating system: Ubuntu
- Configuration management: Ansible
- Web service: nginx

## Variable Precedence Demonstration

The web server role defines default variables in:

ansible/roles/web_server/defaults/main.yml

Additional variables are maintained with the inventory under:

ansible/inventory/group_vars/
ansible/inventory/host_vars/

The lab demonstrated the following relative precedence for the variable sources used:

role defaults < group_vars < host_vars < extra vars

Example values:

Role default:

web_server_environment: production

Group variable:

web_server_environment: staging

Host variable:

web_server_environment: production-host

Extra variable:

web_server_environment=emergency-override

The extra variable resolved to:

emergency-override

The web server title was resolved from the managed group variable.

## Inventory Variable Structure

The final inventory variable layout is:

ansible/inventory/group_vars/managed.yml
ansible/inventory/group_vars/all/vault.yml
ansible/inventory/host_vars/ansible-managed-01.yml

Moving the variables next to the inventory ensured that they were consistently discovered when executing the playbook.

## Ansible Vault

Sensitive values are stored in:

ansible/inventory/group_vars/all/vault.yml

The Vault file is encrypted and begins with:

$ANSIBLE_VAULT;1.1;AES256

The Vault password is not stored in the repository.

The encrypted variables include a lab API key and service account used only for demonstrating secret-management practices.

## Secret Deployment

The web_server role deploys a protected configuration file using a Jinja2 template.

Template:

ansible/roles/web_server/templates/devops-lab-secret.conf.j2

Destination:

/etc/devops-lab-secret.conf

Permissions:

600 root root

The Ansible task uses:

no_log: true

This prevents secret values from appearing in normal Ansible task output.

The resulting secret file was validated without printing its contents.

## Troubleshooting Scenario

The initial Vault-backed role task failed while no_log was enabled.

The failure was investigated without exposing the secret.

The following components were validated individually:

1. Vault file encryption
2. Vault password and decryption
3. Vault variable definitions
4. Variable data types
5. Root write access to /etc
6. File permissions
7. Ansible copy module
8. Individual Vault variables
9. Combined Vault variables
10. Jinja2 rendering
11. Template module
12. Alternate destination paths
13. Role execution with harmless extra variables

A safe assertion was then added inside the role.

The assertion showed:

vault_lab_api_key is defined = false

during playbook execution even though the variable was available during ad-hoc commands.

This isolated the issue to variable discovery scope.

The group_vars, host_vars, and Vault file were moved under the inventory directory:

ansible/inventory/group_vars/
ansible/inventory/host_vars/

After the relocation, the role assertion succeeded and the Vault-protected configuration deployed successfully.

This demonstrated systematic root-cause isolation without disabling no_log or exposing secret values.

## Convergence

After changing the variable structure, the next playbook execution updated the resources affected by the newly resolved variables.

The run reported changes to:

- Managed web page
- Managed configuration file
- nginx handler

This represented convergence to the newly defined desired state.

## Idempotency Validation

After convergence completed, the complete playbook was executed again without changing configuration.

Final result:

ansible-managed-01 : ok=9 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0

This proves that the automation is idempotent.

The Vault-backed secret task also returned:

ok: [ansible-managed-01]

No unnecessary secret-file update occurred.

## Security Controls

The implementation demonstrates several secret-management controls:

- Vault file encrypted at rest in Git
- Vault password excluded from Git
- no_log enabled on secret deployment task
- Secret file owned by root
- Secret file permissions set to 0600
- Validation performed without printing secret contents
- Troubleshooting performed without disabling secret masking

## Production Relevance

This pattern can be applied to production configuration management for:

- API credentials
- Application service accounts
- Environment-specific configuration
- Database credentials
- Deployment secrets
- Internal service configuration

In larger environments, the same principles can be integrated with centralized secret-management platforms such as HashiCorp Vault, AWS Secrets Manager, or cloud-native secret systems.

## Interview Explanation

A concise interview explanation:

"I used Ansible variables and Vault to build repeatable configuration management for a Linux host. I demonstrated variable precedence using role defaults, group variables, host variables, and extra variables. I encrypted sensitive configuration with Ansible Vault, consumed the values through a Jinja2 template, protected the deployed secret file with root ownership and 0600 permissions, and used no_log to prevent secrets from appearing in automation logs.

During implementation, the Vault variables worked in ad-hoc commands but were undefined inside the role. I systematically ruled out encryption, SSH, sudo, filesystem permissions, template rendering, and the template module. I then identified the root cause as variable discovery scope and moved group_vars and host_vars alongside the inventory. After convergence, a full repeat execution returned changed=0 and failed=0, demonstrating idempotency."
