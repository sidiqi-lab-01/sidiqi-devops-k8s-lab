# Bash Command Reference

## Script Interpreter

Example:

    #!/usr/bin/env bash

Usage:

Runs the script using Bash found in the environment.

## Run Script

Command:

    bash script.sh

Usage:

Executes a Bash script.

## Make Script Executable

Command:

    chmod +x script.sh

Usage:

Adds executable permission.

## Execute Script

Command:

    ./script.sh

Usage:

Runs an executable shell script.

## Strict Mode

Command:

    set -euo pipefail

Usage:

Improves automation safety.

-e exits on command failure.
-u fails on undefined variables.
pipefail detects failures anywhere in a pipeline.

## Variable

Commands:

    NAME="devops"
    echo "$NAME"

Usage:

Creates and references a shell variable.

## Environment Variable

Command:

    export AWS_REGION="us-east-2"

Usage:

Exports a variable so child processes can use it.

## Command Substitution

Command:

    CURRENT_BRANCH="$(git branch --show-current)"

Usage:

Stores command output in a variable.

## Conditional

Example:

    if [[ -f file.txt ]]; then
        echo "File exists"
    fi

Usage:

Executes commands only when a condition is true.

## Loop

Example:

    for service in api users orders; do
        echo "$service"
    done

Usage:

Repeats commands for multiple values.

## Exit Code

Command:

    echo $?

Usage:

Displays the previous command's exit status.

Zero normally means success.

## Logical AND

Command:

    terraform validate && echo "VALID"

Usage:

Executes the second command only when the first succeeds.

## Logical OR

Command:

    command || echo "Command failed"

Usage:

Executes the second command when the first fails.

## Pipeline

Command:

    docker ps | grep api

Usage:

Sends output from one command into another.

## Redirect Output

Command:

    command > output.txt

Usage:

Writes standard output to a file and replaces existing content.

## Append Output

Command:

    command >> output.txt

Usage:

Appends standard output to a file.

## Redirect Error

Command:

    command 2> error.log

Usage:

Writes standard error to a file.

## Function

Example:

    check_service() {
        systemctl status "$1"
    }

Usage:

Defines reusable shell logic.

## First Script Argument

Command:

    echo "$1"

Usage:

Displays the first argument supplied to a script.

## All Script Arguments

Command:

    echo "$@"

Usage:

Displays all arguments passed to a script.

## Debug Script

Command:

    bash -x script.sh

Usage:

Prints commands as Bash executes them.

## Syntax Check

Command:

    bash -n script.sh

Usage:

Checks Bash syntax without executing the script.
