#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "========================================"
echo " ENGINEERING ROADMAP ISSUE SEEDER"
echo " Repository: $REPO"
echo "========================================"

ensure_label() {
  local label="$1"
  local description="$2"
  local color="$3"

  if gh label list --repo "$REPO" --limit 200 --json name --jq '.[].name' | grep -Fxq "$label"; then
    echo "[OK] Label exists: $label"
  else
    gh label create "$label" \
      --repo "$REPO" \
      --description "$description" \
      --color "$color"
    echo "[CREATED] Label: $label"
  fi
}

create_issue() {
  local milestone="$1"
  local domain="$2"
  local priority="$3"
  local title="$4"
  local objective="$5"

  if gh issue list \
      --repo "$REPO" \
      --state all \
      --limit 500 \
      --json title \
      --jq '.[].title' | grep -Fxq "$title"; then

    echo "[SKIP] $title"
    return
  fi

  body=$(cat <<BODY
## Description

$objective

## Objectives

- Build and validate the capability hands-on.
- Document implementation commands and architecture.
- Capture troubleshooting and validation evidence.
- Store reusable automation in GitHub where appropriate.
- Explain how the capability applies to production DevOps/SRE environments.

## Interview Relevance

This work supports senior DevOps, infrastructure engineering, Kubernetes, automation, operations, and technical leadership interview preparation.

## Completion Criteria

- [ ] Implementation completed
- [ ] Validation completed
- [ ] Troubleshooting scenarios tested
- [ ] Documentation committed
- [ ] Automation committed where applicable
- [ ] Pull request reviewed and merged
BODY
)

  gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --body "$body" \
    --label "$domain" \
    --label "$priority" \
    --milestone "$milestone"

  echo "[CREATED] $milestone -> $title"
}

echo
echo "=== ENSURE LABELS ==="

ensure_label "ansible" "Ansible configuration management" "6F42C1"
ensure_label "docker" "Docker and container engineering" "2496ED"
ensure_label "kubernetes" "Kubernetes and RKE2 engineering" "326CE5"
ensure_label "helm" "Helm package management" "0F1689"
ensure_label "gitops" "GitOps deployment and operations" "5319E7"
ensure_label "cicd" "Continuous integration and delivery" "2088FF"
ensure_label "storage" "Storage and persistent data" "8B5CF6"
ensure_label "multisite" "Multi-site architecture and operations" "7057FF"
ensure_label "airgap" "Disconnected and air-gapped environments" "555555"
ensure_label "devsecops" "DevSecOps and security engineering" "D73A4A"
ensure_label "ai-engineering" "AI-assisted engineering workflows" "A371F7"
ensure_label "operations" "Operations and troubleshooting" "FBCA04"
ensure_label "leadership" "Engineering leadership and interview readiness" "BFD4F2"

echo
echo "=== MILESTONE 5: ANSIBLE ==="

create_issue \
  "Ansible Configuration Management" \
  "ansible" \
  "P0" \
  "Install and Configure Ansible Control Environment" \
  "Install Ansible, establish the control-node environment, validate connectivity, and document the Ansible architecture."

create_issue \
  "Ansible Configuration Management" \
  "ansible" \
  "P0" \
  "Build Ansible Inventory and Managed Host Connectivity" \
  "Create static and dynamic inventory patterns, configure SSH connectivity, and validate Ansible communication with managed Linux hosts."

create_issue \
  "Ansible Configuration Management" \
  "ansible" \
  "P1" \
  "Develop Ansible Playbooks Roles and Handlers" \
  "Build reusable playbooks and roles for Linux configuration, package installation, services, users, files, and handlers."

create_issue \
  "Ansible Configuration Management" \
  "ansible" \
  "P1" \
  "Validate Ansible Idempotency Variables and Vault" \
  "Demonstrate idempotency, variable precedence, templates, secrets handling with Ansible Vault, and repeatable configuration management."

echo
echo "=== MILESTONE 6: DOCKER ==="

create_issue \
  "Docker & Microservices" \
  "docker" \
  "P0" \
  "Install Docker and Validate Container Runtime" \
  "Install Docker Engine, validate images and containers, inspect container networking and storage, and document runtime operations."

create_issue \
  "Docker & Microservices" \
  "docker" \
  "P0" \
  "Build Containerized Microservice Application" \
  "Create a simple microservice application, write a Dockerfile, build an image, run the container, and validate application connectivity."

create_issue \
  "Docker & Microservices" \
  "docker" \
  "P1" \
  "Build Multi-Container Application with Docker Compose" \
  "Deploy multiple cooperating services using Docker Compose and validate service discovery, networking, health checks, and dependencies."

create_issue \
  "Docker & Microservices" \
  "docker" \
  "P1" \
  "Implement Container Image Versioning and Security" \
  "Implement image tags, image inspection, vulnerability awareness, least-privilege practices, and repeatable image lifecycle operations."

echo
echo "=== MILESTONE 7: RKE2 ==="

create_issue \
  "RKE2 Kubernetes" \
  "kubernetes" \
  "P0" \
  "Design RKE2 Kubernetes Cluster Architecture" \
  "Document RKE2 server, agent, networking, datastore, load balancing, certificates, ports, and production architecture requirements."

create_issue \
  "RKE2 Kubernetes" \
  "kubernetes" \
  "P0" \
  "Install and Validate RKE2 Kubernetes Server" \
  "Deploy an RKE2 server node and validate Kubernetes API, system pods, nodes, networking, and cluster health."

create_issue \
  "RKE2 Kubernetes" \
  "kubernetes" \
  "P0" \
  "Join RKE2 Worker Nodes to Kubernetes Cluster" \
  "Configure RKE2 agents, securely join worker nodes, validate scheduling, and document node lifecycle operations."

create_issue \
  "RKE2 Kubernetes" \
  "kubernetes" \
  "P1" \
  "Deploy and Troubleshoot Kubernetes Workloads" \
  "Deploy applications using Pods, Deployments, Services, ConfigMaps, Secrets, probes, and troubleshoot common Kubernetes failures."

echo
echo "=== MILESTONE 8: HELM AND GITOPS ==="

create_issue \
  "Helm & GitOps" \
  "helm" \
  "P0" \
  "Package Microservice Application with Helm" \
  "Create a reusable Helm chart containing Kubernetes deployment, service, configuration, health checks, and application values."

create_issue \
  "Helm & GitOps" \
  "helm" \
  "P1" \
  "Implement Helm Environment Values and Release Management" \
  "Build environment-specific Helm values and demonstrate install, upgrade, rollback, history, validation, and release management."

create_issue \
  "Helm & GitOps" \
  "gitops" \
  "P0" \
  "Install and Configure Argo CD" \
  "Deploy Argo CD into Kubernetes, configure access, connect the Git repository, and validate application synchronization."

create_issue \
  "Helm & GitOps" \
  "gitops" \
  "P0" \
  "Implement GitOps Deployment with Argo CD" \
  "Deploy the microservice from Git using Argo CD and validate synchronization, drift detection, self-healing, rollback, and Git-based change control."

echo
echo "=== MILESTONE 9: CI/CD ==="

create_issue \
  "CI/CD & Artifact Management" \
  "cicd" \
  "P0" \
  "Build GitHub Actions CI Pipeline" \
  "Create a CI workflow that validates code, scripts, configuration, and application builds on pull requests."

create_issue \
  "CI/CD & Artifact Management" \
  "cicd" \
  "P0" \
  "Automate Docker Image Build and Publication" \
  "Build, tag, validate, and publish application container images automatically through CI/CD."

create_issue \
  "CI/CD & Artifact Management" \
  "cicd" \
  "P1" \
  "Automate Infrastructure and Configuration Validation" \
  "Add automated Terraform, Ansible, Bash, Helm, and Kubernetes validation into the CI pipeline."

create_issue \
  "CI/CD & Artifact Management" \
  "cicd" \
  "P1" \
  "Implement Artifact Versioning and Promotion Workflow" \
  "Design artifact versioning, release metadata, promotion between environments, traceability, and rollback controls."

echo
echo "=== MILESTONE 10: STORAGE ==="

create_issue \
  "Storage" \
  "storage" \
  "P1" \
  "Review Linux and Container Storage Architecture" \
  "Document block, file, ephemeral, persistent, Docker, and Kubernetes storage models and validate Linux storage operations."

create_issue \
  "Storage" \
  "storage" \
  "P0" \
  "Implement Kubernetes Persistent Volumes and Claims" \
  "Create PersistentVolumes and PersistentVolumeClaims and validate application data persistence."

create_issue \
  "Storage" \
  "storage" \
  "P1" \
  "Deploy Stateful Kubernetes Workload" \
  "Deploy a StatefulSet-backed workload and validate stable identity, persistent storage, restart behavior, and recovery."

create_issue \
  "Storage" \
  "storage" \
  "P1" \
  "Test Storage Failure Recovery and Backup Concepts" \
  "Test storage failure scenarios and document backup, restore, snapshots, disaster recovery, and data protection considerations."

echo
echo "=== MILESTONE 11: MULTI-SITE ==="

create_issue \
  "Multi-Site Kubernetes" \
  "multisite" \
  "P0" \
  "Design Multi-Site Kubernetes Architecture" \
  "Design a multi-site Kubernetes architecture covering clusters, networking, DNS, ingress, GitOps, security, failure domains, and operations."

create_issue \
  "Multi-Site Kubernetes" \
  "multisite" \
  "P0" \
  "Build Second Kubernetes Environment" \
  "Deploy or simulate a second Kubernetes cluster/site and establish independent cluster lifecycle management."

create_issue \
  "Multi-Site Kubernetes" \
  "multisite" \
  "P1" \
  "Deploy Application Across Multiple Kubernetes Sites" \
  "Deploy the same application to multiple clusters and validate configuration separation and consistent releases."

create_issue \
  "Multi-Site Kubernetes" \
  "multisite" \
  "P1" \
  "Test Multi-Site Failure and Recovery Scenarios" \
  "Simulate site or cluster failure and document operational response, recovery strategy, availability tradeoffs, and leadership decisions."

echo
echo "=== MILESTONE 12: AIR GAP ==="

create_issue \
  "Air-Gapped / Disconnected Environment" \
  "airgap" \
  "P0" \
  "Design Air-Gapped Kubernetes Deployment Architecture" \
  "Document disconnected installation architecture covering images, packages, charts, repositories, certificates, DNS, and controlled software transfer."

create_issue \
  "Air-Gapped / Disconnected Environment" \
  "airgap" \
  "P0" \
  "Build Local Container Registry for Disconnected Operations" \
  "Deploy and validate a local registry suitable for hosting required application and Kubernetes container images."

create_issue \
  "Air-Gapped / Disconnected Environment" \
  "airgap" \
  "P1" \
  "Prepare Offline Kubernetes Helm and Image Artifacts" \
  "Create a repeatable workflow to collect, version, verify, transfer, and consume images and Helm artifacts without Internet access."

create_issue \
  "Air-Gapped / Disconnected Environment" \
  "airgap" \
  "P1" \
  "Simulate Disconnected Kubernetes Deployment" \
  "Deploy an application using only locally available artifacts and document disconnected troubleshooting and maintenance procedures."

echo
echo "=== MILESTONE 13: DEVSECOPS ==="

create_issue \
  "DevSecOps" \
  "devsecops" \
  "P0" \
  "Implement Repository Secret and Credential Controls" \
  "Validate that credentials are excluded from source control and establish secure secret-management and scanning practices."

create_issue \
  "DevSecOps" \
  "devsecops" \
  "P1" \
  "Add Infrastructure and Container Security Scanning" \
  "Integrate security checks for infrastructure code, configuration, dependencies, and container images."

create_issue \
  "DevSecOps" \
  "devsecops" \
  "P1" \
  "Implement Kubernetes Security Controls" \
  "Apply RBAC, namespace isolation, security contexts, least privilege, secrets practices, and workload security controls."

create_issue \
  "DevSecOps" \
  "devsecops" \
  "P1" \
  "Build DevSecOps Security Validation Pipeline" \
  "Integrate security validation into CI/CD and define handling of findings, severity, exceptions, and remediation."

echo
echo "=== MILESTONE 14: AI ==="

create_issue \
  "AI-Assisted Engineering" \
  "ai-engineering" \
  "P1" \
  "Document AI-Assisted Infrastructure Development Workflow" \
  "Create a controlled workflow for using AI assistants to accelerate infrastructure and software development while preserving engineering review."

create_issue \
  "AI-Assisted Engineering" \
  "ai-engineering" \
  "P1" \
  "Use AI to Generate and Review Automation Code" \
  "Demonstrate AI-assisted Bash, Terraform, Ansible, Docker, Helm, or Kubernetes development with validation before acceptance."

create_issue \
  "AI-Assisted Engineering" \
  "ai-engineering" \
  "P1" \
  "Use AI for Troubleshooting and Root Cause Analysis" \
  "Document a repeatable workflow where AI assists log analysis and troubleshooting while engineers validate evidence and conclusions."

create_issue \
  "AI-Assisted Engineering" \
  "ai-engineering" \
  "P2" \
  "Define AI Engineering Governance and Review Controls" \
  "Document controls for security, proprietary data, hallucination risk, code review, testing, traceability, and human approval."

echo
echo "=== MILESTONE 15: OPERATIONS ==="

create_issue \
  "Operations & Troubleshooting" \
  "operations" \
  "P0" \
  "Build End-to-End Infrastructure Health Check Toolkit" \
  "Create health-check automation covering Linux, networking, containers, Kubernetes, applications, and infrastructure dependencies."

create_issue \
  "Operations & Troubleshooting" \
  "operations" \
  "P0" \
  "Practice Kubernetes Incident Troubleshooting Scenarios" \
  "Create and resolve controlled failures involving Pods, networking, DNS, storage, configuration, images, and node health."

create_issue \
  "Operations & Troubleshooting" \
  "operations" \
  "P1" \
  "Implement Logging Metrics and Operational Observability" \
  "Establish practical logging, metrics, events, health checks, and troubleshooting visibility for the lab environment."

create_issue \
  "Operations & Troubleshooting" \
  "operations" \
  "P1" \
  "Document Root Cause Analysis and Incident Response Process" \
  "Develop an RCA and incident-management workflow covering detection, mitigation, evidence, root cause, corrective actions, and lessons learned."

echo
echo "=== MILESTONE 16: LEADERSHIP ==="

create_issue \
  "Leadership / Interview Readiness" \
  "leadership" \
  "P0" \
  "Build Senior DevOps Architecture Presentation" \
  "Create an architecture walkthrough that explains requirements, design decisions, implementation, security, operations, and business tradeoffs."

create_issue \
  "Leadership / Interview Readiness" \
  "leadership" \
  "P0" \
  "Prepare Senior DevOps Technical Interview Stories" \
  "Develop concise STAR-style examples covering troubleshooting, automation, leadership, conflict, requirements, failures, and technical decisions."

create_issue \
  "Leadership / Interview Readiness" \
  "leadership" \
  "P0" \
  "Prepare Requirements to Architecture Leadership Scenario" \
  "Demonstrate conversion of an internal customer requirement into scope, architecture, backlog, implementation, validation, and stakeholder communication."

create_issue \
  "Leadership / Interview Readiness" \
  "leadership" \
  "P0" \
  "Conduct End-to-End DevOps Interview Lab Demonstration" \
  "Prepare and rehearse a concise live demonstration connecting AWS, Linux, networking, IaC, automation, containers, Kubernetes, GitOps, security, and operations."

echo
echo "========================================"
echo " ROADMAP SEEDING COMPLETE"
echo "========================================"
