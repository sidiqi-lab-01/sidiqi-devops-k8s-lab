# Terraform Command Reference

## Version

Command:

    terraform version

Usage:

Displays the installed Terraform version.

## Initialize

Command:

    terraform init

Usage:

Initializes providers, modules, and backend configuration.

## Format

Command:

    terraform fmt

Usage:

Formats Terraform files.

## Recursive Format

Command:

    terraform fmt -recursive

Usage:

Formats Terraform configuration in nested directories.

## Validate

Command:

    terraform validate

Usage:

Validates Terraform configuration syntax and references.

## Plan

Command:

    terraform plan

Usage:

Shows infrastructure changes Terraform proposes to make.

## Save Plan

Command:

    terraform plan -out=tfplan

Usage:

Creates a saved execution plan for controlled deployment.

## Apply Saved Plan

Command:

    terraform apply tfplan

Usage:

Applies exactly the previously saved plan.

## Apply

Command:

    terraform apply

Usage:

Plans and applies infrastructure changes after confirmation.

## Outputs

Command:

    terraform output

Usage:

Displays values defined as Terraform outputs.

## State List

Command:

    terraform state list

Usage:

Lists resources currently managed by Terraform.

## State Show

Command:

    terraform state show aws_vpc.main

Usage:

Displays Terraform state information for a specific resource.

## Show

Command:

    terraform show

Usage:

Displays the current state or a saved plan.

## Providers

Command:

    terraform providers

Usage:

Shows providers required by the configuration and state.

## Refresh-Only Plan

Command:

    terraform plan -refresh-only

Usage:

Compares Terraform state with real infrastructure to detect drift.

## Destroy Plan

Command:

    terraform plan -destroy

Usage:

Shows what Terraform would remove without actually destroying it.

## Destroy

Command:

    terraform destroy

Usage:

Destroys Terraform-managed infrastructure. Use carefully.

## Variable

Command:

    terraform plan -var="environment=dev"

Usage:

Supplies a Terraform variable directly from the command line.

## Variable File

Command:

    terraform plan -var-file="dev.tfvars"

Usage:

Loads variables from a tfvars file.

## Dependency Graph

Command:

    terraform graph

Usage:

Produces the Terraform dependency graph.

## Recommended Workflow

Commands:

    terraform fmt -recursive
    terraform validate
    terraform plan -out=tfplan
    terraform apply tfplan

Usage:

Provides a controlled IaC validation and deployment workflow.
