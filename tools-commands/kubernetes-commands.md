# Kubernetes Command Reference

## Overview

This document provides commonly used Kubernetes and `kubectl` commands for cluster administration, workload deployment, troubleshooting, networking, configuration, security, scaling, and day-to-day DevOps operations.

The examples assume that `kubectl` is installed and that a valid kubeconfig is configured.

---

# 1. kubectl Basics

## Check kubectl Version

```bash
kubectl version
Displays Kubernetes client and server version information.

Client-only version:

kubectl version --client
Usage

Use this when validating that kubectl is installed or checking Kubernetes version compatibility.

Display kubectl Help
kubectl --help

Help for a specific command:

kubectl get --help
kubectl create --help
kubectl apply --help
2. Cluster Information
Display Cluster Information
kubectl cluster-info

Displays the Kubernetes API server and cluster service endpoints.

Display Detailed Cluster Information
kubectl cluster-info dump

Useful for deep troubleshooting.

Because the output is very large, redirect it to a file when necessary:

kubectl cluster-info dump > cluster-dump.txt
Check API Availability
kubectl get --raw='/readyz'

Verbose API health:

kubectl get --raw='/readyz?verbose'
3. Node Management
List Nodes
kubectl get nodes

Detailed view:

kubectl get nodes -o wide
Usage

Shows whether Kubernetes nodes are registered and healthy.

Example:

NAME             STATUS   ROLES                VERSION
rke2-server-01   Ready    control-plane,etcd   v1.36.4+rke2r1
rke2-worker-01   Ready    <none>               v1.36.4+rke2r1
rke2-worker-02   Ready    <none>               v1.36.4+rke2r1
Describe a Node
kubectl describe node rke2-worker-01
Usage

Useful for troubleshooting:

CPU and memory capacity
node conditions
taints
labels
allocated resources
kubelet status
scheduling problems
Display Node Labels
kubectl get nodes --show-labels

For one node:

kubectl get node rke2-worker-01 --show-labels

Display selected labels as columns:

kubectl get nodes -L environment,node-role
Add a Node Label
kubectl label node rke2-worker-01 environment=lab

Add or update:

kubectl label node rke2-worker-01 environment=production --overwrite
Remove a Node Label
kubectl label node rke2-worker-01 environment-

The trailing - removes the label.

Cordon a Node
kubectl cordon rke2-worker-01
Usage

Marks the node unschedulable.

Existing workloads continue running, but new workloads will not be scheduled there.

Uncordon a Node
kubectl uncordon rke2-worker-01

Allows scheduling again.

Drain a Node
kubectl drain rke2-worker-01 \
  --ignore-daemonsets \
  --delete-emptydir-data
Usage

Safely removes workloads before maintenance or node replacement.

4. Namespaces
List Namespaces
kubectl get namespaces

Short form:

kubectl get ns
Create a Namespace
kubectl create namespace dev

Short form:

kubectl create ns dev
Delete a Namespace
kubectl delete namespace dev

Warning: deleting a namespace deletes resources contained inside it.

Run a Command Against a Namespace
kubectl get pods -n kube-system
Set Default Namespace for Current Context
kubectl config set-context --current --namespace=dev
5. Pods
List Pods
kubectl get pods

All namespaces:

kubectl get pods -A

Detailed information:

kubectl get pods -o wide

Specific namespace:

kubectl get pods -n kube-system
Describe a Pod
kubectl describe pod my-pod

Namespace example:

kubectl describe pod my-pod -n dev
Usage

One of the most important troubleshooting commands.

Check:

container state
image
readiness
restart count
volumes
environment
node assignment
events
Create a Temporary Pod
kubectl run test-pod \
  --image=busybox:1.36 \
  --restart=Never \
  -- sleep 3600
Create an Interactive Debug Pod
kubectl run debug \
  --image=busybox:1.36 \
  --restart=Never \
  -it \
  -- sh

Delete when finished:

kubectl delete pod debug
Delete a Pod
kubectl delete pod my-pod

A Deployment-managed pod will normally be recreated automatically.

Force Delete a Pod

Use only when necessary:

kubectl delete pod my-pod \
  --grace-period=0 \
  --force
6. Pod Logs
View Pod Logs
kubectl logs my-pod
Follow Logs in Real Time
kubectl logs -f my-pod
Logs From a Specific Container
kubectl logs my-pod -c application
Previous Container Logs
kubectl logs my-pod --previous
Usage

Very useful when a container is repeatedly crashing.

Show Recent Logs
kubectl logs my-pod --tail=100
Logs Since a Time Period
kubectl logs my-pod --since=10m
7. Execute Commands Inside Containers
Open a Shell
kubectl exec -it my-pod -- /bin/sh

If Bash exists:

kubectl exec -it my-pod -- /bin/bash
Run a Single Command
kubectl exec my-pod -- hostname

Example:

kubectl exec my-pod -- cat /etc/resolv.conf
Execute Against Specific Container
kubectl exec -it my-pod -c application -- /bin/sh
8. Deployments
List Deployments
kubectl get deployments

Short form:

kubectl get deploy
Create a Deployment
kubectl create deployment nginx \
  --image=nginx:latest
Create Deployment With Replicas
kubectl create deployment nginx \
  --image=nginx:latest \
  --replicas=3
Describe Deployment
kubectl describe deployment nginx
Scale Deployment
kubectl scale deployment nginx --replicas=5
Update Container Image
kubectl set image deployment/nginx \
  nginx=nginx:1.29
Check Rollout Status
kubectl rollout status deployment/nginx
Rollout History
kubectl rollout history deployment/nginx
Roll Back Deployment
kubectl rollout undo deployment/nginx

Rollback to a specific revision:

kubectl rollout undo deployment/nginx --to-revision=2
Restart Deployment
kubectl rollout restart deployment/nginx
9. ReplicaSets
List ReplicaSets
kubectl get replicasets

Short form:

kubectl get rs
Describe ReplicaSet
kubectl describe rs <replicaset-name>

Normally ReplicaSets are managed through Deployments rather than directly.

10. DaemonSets
List DaemonSets
kubectl get daemonsets -A

Short form:

kubectl get ds -A

Example in RKE2:

kubectl get ds -n kube-system

Canal typically runs as a DaemonSet so each node receives a networking pod.

11. StatefulSets
List StatefulSets
kubectl get statefulsets

Short form:

kubectl get sts
Describe StatefulSet
kubectl describe statefulset database

Useful for applications requiring stable identity or persistent storage.

12. Services
List Services
kubectl get services

Short form:

kubectl get svc

All namespaces:

kubectl get svc -A
Expose Deployment
kubectl expose deployment nginx \
  --port=80 \
  --target-port=80
Create ClusterIP Service
kubectl expose deployment nginx \
  --type=ClusterIP \
  --port=80

ClusterIP is reachable only inside the Kubernetes cluster.

Create NodePort Service
kubectl expose deployment nginx \
  --type=NodePort \
  --port=80

Inspect assigned NodePort:

kubectl get svc nginx
Describe Service
kubectl describe svc nginx
Show Service Endpoints
kubectl get endpoints

For a specific service:

kubectl get endpoints nginx
13. DNS Troubleshooting
Test Kubernetes DNS
kubectl run dns-test \
  --image=busybox:1.36 \
  --restart=Never \
  -- nslookup kubernetes.default.svc.cluster.local

View result:

kubectl logs dns-test

Delete test pod:

kubectl delete pod dns-test
Check CoreDNS
kubectl get pods -n kube-system | grep coredns

Logs:

kubectl logs -n kube-system \
  -l k8s-app=kube-dns
14. ConfigMaps
List ConfigMaps
kubectl get configmaps

Short form:

kubectl get cm
Create ConfigMap From Literal
kubectl create configmap app-config \
  --from-literal=environment=dev \
  --from-literal=log_level=info
Create ConfigMap From File
kubectl create configmap app-config \
  --from-file=application.properties
Inspect ConfigMap
kubectl get configmap app-config -o yaml
Delete ConfigMap
kubectl delete configmap app-config
15. Secrets
Create Generic Secret
kubectl create secret generic db-secret \
  --from-literal=username=myuser \
  --from-literal=password='REPLACE_WITH_SECRET'

Do not store real plaintext credentials in Git.

List Secrets
kubectl get secrets
Describe Secret
kubectl describe secret db-secret

describe does not normally display decoded secret values.

Delete Secret
kubectl delete secret db-secret
16. Apply Kubernetes YAML
Apply Manifest
kubectl apply -f deployment.yaml

Directory:

kubectl apply -f kubernetes/

Remote manifests may also be supported, but production workflows should use reviewed and version-controlled manifests.

Preview Changes
kubectl diff -f deployment.yaml
Server-Side Dry Run
kubectl apply \
  --dry-run=server \
  -f deployment.yaml
Client-Side Dry Run
kubectl apply \
  --dry-run=client \
  -f deployment.yaml
Delete Manifest Resources
kubectl delete -f deployment.yaml
17. Generate YAML
Generate Deployment YAML
kubectl create deployment nginx \
  --image=nginx:latest \
  --dry-run=client \
  -o yaml

Save it:

kubectl create deployment nginx \
  --image=nginx:latest \
  --dry-run=client \
  -o yaml > deployment.yaml
Generate Service YAML
kubectl expose deployment nginx \
  --port=80 \
  --target-port=80 \
  --dry-run=client \
  -o yaml
18. Resource Output Formats
YAML Output
kubectl get pod my-pod -o yaml
JSON Output
kubectl get pod my-pod -o json
Wide Output
kubectl get pods -o wide
Custom Columns
kubectl get pods \
  -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,IP:.status.podIP
JSONPath
kubectl get nodes \
  -o jsonpath='{.items[*].metadata.name}'

Ready condition example:

kubectl get node rke2-worker-01 \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
19. Resource Usage
Node Resource Usage
kubectl top nodes
Pod Resource Usage
kubectl top pods

All namespaces:

kubectl top pods -A

Requires Metrics Server.

20. Events
List Events
kubectl get events

Sort by creation time:

kubectl get events \
  --sort-by=.metadata.creationTimestamp

All namespaces:

kubectl get events -A \
  --sort-by=.metadata.creationTimestamp
Usage

Events are extremely valuable when troubleshooting:

failed scheduling
image pulls
volume mounting
readiness failures
node issues
21. Kubernetes Contexts
Display Current Context
kubectl config current-context
List Contexts
kubectl config get-contexts
Switch Context
kubectl config use-context <context-name>
Show Current Configuration
kubectl config view

Be careful when sharing kubeconfig output because it can contain sensitive authentication data.

22. Port Forwarding
Forward Local Port to Pod
kubectl port-forward pod/my-pod 8080:80
Forward Local Port to Service
kubectl port-forward service/nginx 8080:80

Useful for testing applications without exposing them externally.

23. Copy Files
Local to Pod
kubectl cp ./config.txt my-pod:/tmp/config.txt
Pod to Local
kubectl cp my-pod:/tmp/output.txt ./output.txt

For a namespace:

kubectl cp dev/my-pod:/tmp/output.txt ./output.txt
24. Scheduling
Determine Where Pods Run
kubectl get pods -o wide
Run Test Pod on Specific Node
kubectl run worker-test \
  --image=busybox:1.36 \
  --restart=Never \
  --overrides='
{
  "spec": {
    "nodeName": "rke2-worker-01",
    "containers": [
      {
        "name": "worker-test",
        "image": "busybox:1.36",
        "command": ["sleep","3600"]
      }
    ]
  }
}'
25. Taints and Tolerations
Display Taints
kubectl describe node rke2-server-01 | grep -i taint
Add Taint
kubectl taint nodes rke2-worker-01 \
  dedicated=database:NoSchedule
Remove Taint
kubectl taint nodes rke2-worker-01 \
  dedicated=database:NoSchedule-
26. RBAC
List Roles
kubectl get roles -A
List ClusterRoles
kubectl get clusterroles
List RoleBindings
kubectl get rolebindings -A
List ClusterRoleBindings
kubectl get clusterrolebindings
Check Permissions
kubectl auth can-i get pods

Example:

kubectl auth can-i create deployments -n dev

List available permissions:

kubectl auth can-i --list
27. Persistent Storage
List Persistent Volumes
kubectl get pv
List Persistent Volume Claims
kubectl get pvc

All namespaces:

kubectl get pvc -A
List Storage Classes
kubectl get storageclass

Short form:

kubectl get sc
Describe PVC
kubectl describe pvc <pvc-name>

Useful for troubleshooting storage binding problems.

28. Troubleshooting Pods
Pod Stuck in Pending

Start with:

kubectl describe pod <pod-name>

Then:

kubectl get events \
  --sort-by=.metadata.creationTimestamp

Common causes:

insufficient CPU
insufficient memory
node selectors
taints
missing PVC
scheduler constraints
CrashLoopBackOff
kubectl describe pod <pod-name>

Current logs:

kubectl logs <pod-name>

Previous crash logs:

kubectl logs <pod-name> --previous

Common causes:

application crash
incorrect command
missing configuration
failed dependency
bad environment variables
failed health checks
ImagePullBackOff
kubectl describe pod <pod-name>

Look for:

Failed to pull image
ErrImagePull
ImagePullBackOff

Check:

image name
image tag
registry connectivity
registry credentials
imagePullSecrets
Service Not Reachable

Inspect service:

kubectl get svc

Inspect endpoints:

kubectl get endpoints

Inspect pods:

kubectl get pods -o wide

Test DNS:

kubectl run dns-debug \
  --image=busybox:1.36 \
  --restart=Never \
  -- nslookup <service-name>
29. RKE2-Specific Validation
Check Nodes
kubectl get nodes -o wide
Check RKE2 System Pods
kubectl get pods -n kube-system -o wide
Check Canal
kubectl get pods -n kube-system \
  -l k8s-app=canal \
  -o wide
Check CoreDNS
kubectl get pods -n kube-system \
  -l k8s-app=kube-dns \
  -o wide
Check RKE2 Agent Service

Run on a worker:

sudo systemctl status rke2-agent

Logs:

sudo journalctl -u rke2-agent -n 100 --no-pager

Follow logs:

sudo journalctl -u rke2-agent -f
Check RKE2 Server Service

Run on server:

sudo systemctl status rke2-server

Logs:

sudo journalctl -u rke2-server -n 100 --no-pager
30. Useful Short Names

Common Kubernetes resource abbreviations:

Resource	Short Name
Pods	po
Services	svc
Deployments	deploy
ReplicaSets	rs
DaemonSets	ds
StatefulSets	sts
Namespaces	ns
Nodes	no
ConfigMaps	cm
Secrets	secret
PersistentVolumes	pv
PersistentVolumeClaims	pvc
StorageClasses	sc
ServiceAccounts	sa

Examples:

kubectl get po
kubectl get svc
kubectl get deploy
kubectl get ns
kubectl get no
31. High-Value Daily Commands

A DevOps or Kubernetes administrator will frequently use:

kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl get events -A \
  --sort-by=.metadata.creationTimestamp
kubectl get svc -A
kubectl get deploy -A
kubectl top nodes
kubectl top pods -A
kubectl rollout status deployment/<deployment-name>
kubectl exec -it <pod-name> -- /bin/sh

These commands cover a significant portion of normal Kubernetes operational troubleshooting.
