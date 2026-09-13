# Linux Command Reference

## Current Directory

Command:

    pwd

Usage:

Displays the current working directory.

## List Files

Command:

    ls -lah

Usage:

Shows files, permissions, ownership, hidden files, and human-readable sizes.

## Change Directory

Command:

    cd /path/to/directory

Usage:

Changes the working directory.

## Create Directory

Command:

    mkdir -p parent/child

Usage:

Creates a directory and any missing parent directories.

## Copy File

Command:

    cp source destination

Usage:

Copies a file.

## Copy Directory

Command:

    cp -r directory destination

Usage:

Copies a directory recursively.

## Move or Rename

Command:

    mv oldname newname

Usage:

Moves or renames files and directories.

## Remove File

Command:

    rm file

Usage:

Deletes a file.

## Remove Directory

Command:

    rm -r directory

Usage:

Deletes a directory recursively. Use carefully.

## Display File

Command:

    cat file

Usage:

Prints file contents.

## Paginated File View

Command:

    less file

Usage:

Views large files one screen at a time.

## Search Text

Command:

    grep "error" logfile

Usage:

Searches a file for matching text.

## Recursive Search

Command:

    grep -Ri "error" .

Usage:

Searches files recursively.

## Find Files

Command:

    find . -name "*.log"

Usage:

Locates files matching a name pattern.

## Change Permissions

Command:

    chmod 755 script.sh

Usage:

Changes filesystem permissions.

## Change Ownership

Command:

    sudo chown user:group file

Usage:

Changes file owner and group.

## Identity

Command:

    id

Usage:

Shows the current UID, GID, and group memberships.

## Current User

Command:

    whoami

Usage:

Shows the current username.

## Disk Space

Command:

    df -h

Usage:

Shows filesystem disk usage.

## Directory Size

Command:

    du -sh directory

Usage:

Shows total disk usage of a directory.

## Memory

Command:

    free -h

Usage:

Shows system memory and swap utilization.

## Processes

Command:

    ps aux

Usage:

Lists running processes.

## Real-Time Processes

Command:

    top

Usage:

Displays real-time CPU and process activity.

## Listening Ports

Command:

    sudo ss -tulpn

Usage:

Shows listening TCP and UDP ports and owning processes.

## Network Interfaces

Command:

    ip addr

Usage:

Shows network interfaces and IP addresses.

## Routing Table

Command:

    ip route

Usage:

Shows Linux routing information.

## DNS Lookup

Command:

    getent hosts example.com

Usage:

Tests hostname resolution using the system resolver.

## HTTP Test

Command:

    curl http://127.0.0.1:8080

Usage:

Tests an HTTP endpoint.

## HTTP Headers

Command:

    curl -I http://example.com

Usage:

Retrieves HTTP response headers.

## SSH

Command:

    ssh user@server

Usage:

Connects to a remote server using SSH.

## SSH Troubleshooting

Command:

    ssh -vvv user@server

Usage:

Displays detailed SSH connection diagnostics.

## Service Status

Command:

    systemctl status nginx

Usage:

Shows service state and recent logs.

## Restart Service

Command:

    sudo systemctl restart nginx

Usage:

Restarts a systemd service.

## Service Logs

Command:

    journalctl -u nginx

Usage:

Displays systemd logs for a service.

## Follow Service Logs

Command:

    journalctl -u nginx -f

Usage:

Continuously follows service logs.

## Kernel Information

Command:

    uname -a

Usage:

Shows kernel and system information.

## Operating System Information

Command:

    cat /etc/os-release

Usage:

Shows Linux distribution information.

## Package Metadata Update

Command:

    sudo apt update

Usage:

Refreshes Ubuntu/Debian package repository metadata.

## Environment Variables

Command:

    env

Usage:

Displays current environment variables.
