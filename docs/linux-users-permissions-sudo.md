# Linux Users, Groups, Permissions and Sudo

## Overview

This lab demonstrates Linux identity and access management using users, groups, file ownership, permissions, and sudo.

The objective is to understand how Linux controls access to files and directories and how group membership can be used to implement least-privilege access.

## Identity Verification

### Current User

```bash
whoami

Result:

sidiqi
User Identity and Groups
id

Result:

uid=1001(sidiqi) gid=1001(sidiqi) groups=1001(sidiqi),27(sudo),100(users)
Group Membership
groups

Result:

sidiqi sudo users
User and Group Database
Users
getent passwd

Relevant accounts:

root:x:0:0:root:/root:/bin/bash
ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
sidiqi:x:1001:1001:,,9168771173,9168771173:/home/sidiqi:/bin/bash

The system also contains service accounts that use non-login shells such as /usr/sbin/nologin or /bin/false.

Groups
getent group

Relevant groups:

sudo:x:27:ubuntu,sidiqi
users:x:100:sidiqi
ubuntu:x:1000:
sidiqi:x:1001:
File Ownership and Permissions

Repository permissions were inspected with:

ls -l
ls -ld .

The repository files and directories are owned by:

sidiqi:sidiqi

Example directory permission:

drwxrwxr-x

This gives the owner and group read/write/execute access while allowing other users read/execute access.

Sudo Access
sudo -l

Result:

User sidiqi may run the following commands on ip-172-31-16-171:
    (ALL : ALL) ALL

The sudo configuration also includes:

env_reset
secure_path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
use_pty

The sidiqi account has full administrative sudo access. This is appropriate for the lab administrator account, but production application/service accounts should use narrower privileges.

Controlled Permission Lab

A dedicated group and user were created for permission testing:

sudo groupadd labops
sudo useradd --create-home --shell /bin/bash labuser
sudo usermod -aG labops labuser

Verification:

id labuser

Result:

uid=1002(labuser) gid=1003(labuser) groups=1003(labuser),1002(labops)

Group verification:

getent group labops

Result:

labops:x:1002:labuser
Protected Directory

A test directory was created:

sudo mkdir -p /tmp/linux-permissions-lab
sudo chown root:labops /tmp/linux-permissions-lab
sudo chmod 770 /tmp/linux-permissions-lab

Verification:

drwxrwx--- 2 root labops /tmp/linux-permissions-lab

The 770 permission means:

Owner: read/write/execute
Group: read/write/execute
Others: no permissions
Protected File

A test file was created by labuser and then configured with controlled ownership and permissions:

sudo chown root:labops /tmp/linux-permissions-lab/test.txt
sudo chmod 660 /tmp/linux-permissions-lab/test.txt

Final permission state:

-rw-rw---- 1 root labops 22 Sep 10 15:13 test.txt

This means:

Owner root: read/write
Group labops: read/write
Others: no access
Permission Test — Allowed

labuser is a member of labops, so it can write to the protected file:

sudo -u labuser bash -c 'echo "Linux permission test" > /tmp/linux-permissions-lab/test.txt'

The contents were successfully verified:

sudo -u labuser cat /tmp/linux-permissions-lab/test.txt

Result:

Linux permission test
Permission Test — Denied

The sidiqi account is not a member of labops.

Attempting to access the protected file as sidiqi resulted in:

cat: /tmp/linux-permissions-lab/test.txt: Permission denied

This confirms that Linux enforced the configured group-based access control.

Security Observations
Linux identifies users using UIDs and groups using GIDs.
File ownership consists of an owner and group.
Permission bits control read, write, and execute access for owner, group, and others.
Group membership provides a practical mechanism for controlled shared access.
770 on the directory prevents users outside the owner/group from accessing its contents.
660 on the file prevents users outside the owner/group from reading or modifying the file.
Sudo provides administrative access and should be restricted according to the principle of least privilege.
Application and service accounts should generally not receive unrestricted sudo access.
Permission testing should be performed with controlled lab accounts rather than existing system accounts.

Validation Status
 Users inspected
 Groups inspected
 UID/GID verified
 File ownership inspected
 Directory permissions configured
 Group-based access tested
 Read/write access verified
 Unauthorized access denied
 Sudo privileges verified
