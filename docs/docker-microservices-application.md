# Docker Microservices Application

## Objective

Build and validate a containerized microservice application using Docker with independent frontend, API, users, and orders services.

## Architecture

```text
Client
  |
  | :8080
  v
Frontend / Nginx
  |
  | Docker DNS
  v
API :5000
  |
  +----> Users :5001
  |
  +----> Orders :5002
Services
Frontend
Technology: Nginx
Image: sidiqi-devops-frontend:1.0
Host port: 8080
Container port: 80
Provides static HTML
Reverse proxies /api/ requests to the API service
API
Technology: Python, Flask, Gunicorn
Image: sidiqi-devops-api:1.3
Host/container port: 5000
Routes:
/health
/api/health
/api/info
/api/users
/api/orders
Uses environment variables for downstream service URLs
Returns HTTP 503 when a downstream service cannot be reached
Users Service
Technology: Python, Flask, Gunicorn
Image: sidiqi-devops-users:1.0
Host/container port: 5001
Routes:
/
/health
/users
Orders Service
Technology: Python, Flask, Gunicorn
Image: sidiqi-devops-orders:1.0
Host/container port: 5002
Routes:
/
/health
/orders
Docker Network

A user-defined bridge network was created:

sidiqi-microservices-net

Final network membership:

sidiqi-devops-api       -> 172.18.0.2
sidiqi-devops-users     -> 172.18.0.3
sidiqi-devops-orders    -> 172.18.0.4
sidiqi-devops-frontend  -> 172.18.0.5

Containers communicate through Docker DNS using service/container names rather than hard-coded IP addresses.

Examples:

http://sidiqi-devops-api:5000
http://sidiqi-devops-users:5001
http://sidiqi-devops-orders:5002
API Configuration

The API uses environment variables for downstream service discovery:

USERS_SERVICE_URL=http://sidiqi-devops-users:5001
ORDERS_SERVICE_URL=http://sidiqi-devops-orders:5002

This avoids dependency on ephemeral container IP addresses.

Reverse Proxy

The frontend Nginx container accepts client requests on port 8080.

Requests under /api/ are forwarded to:

http://sidiqi-devops-api:5000

This allows clients to access backend services through a single frontend endpoint.

Failure Testing

The users service was deliberately stopped.

Observed behavior:

API /health remained healthy.
API /api/users returned HTTP 503.
Restarting the users service restored normal operation.

This demonstrated downstream dependency isolation and error handling.

Troubleshooting
Port 8080 Conflict

The frontend initially failed because another Nginx container already owned host port 8080.

Error:

Bind for 0.0.0.0:8080 failed: port is already allocated

The conflicting temporary container was identified and removed.

Frontend DNS Resolution

Nginx later reported:

host not found in upstream "sidiqi-devops-api"

Docker network membership and DNS resolution were validated using:

docker network inspect sidiqi-microservices-net
docker run --rm --network sidiqi-microservices-net busybox ping -c 2 sidiqi-devops-api
docker run --rm --network sidiqi-microservices-net curlimages/curl:latest \
  -s http://sidiqi-devops-api:5000/health

The frontend was recreated cleanly and successfully resolved the API service.

API 1.2 Runtime Failure

API image 1.2 built successfully but failed during Gunicorn worker startup.

Error:

NameError: name 'Flask' is not defined

The Docker build itself succeeded because this was a runtime application import problem rather than a Docker build failure.

The missing Flask import was restored:

from flask import Flask, jsonify

A new image version was built:

sidiqi-devops-api:1.3

The application module was validated before deployment:

docker run --rm \
  sidiqi-devops-api:1.3 \
  python -c 'import app; print("Application import: OK")'

The corrected container started successfully.

Final Validation

Frontend:

HTTP/1.1 200 OK

API health through frontend:

{"service":"api","status":"healthy"}

Users through frontend:

{"service":"users","users":[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"},{"id":3,"name":"Charlie"}]}

Orders through frontend:

{"orders":[{"id":101,"item":"Laptop","status":"shipped","user_id":1},{"id":102,"item":"Monitor","status":"processing","user_id":2},{"id":103,"item":"Keyboard","status":"delivered","user_id":3}],"service":"orders"}
Key Engineering Lessons
Successful Docker image builds do not guarantee successful application runtime.
Container logs are essential for diagnosing Gunicorn and application startup failures.
User-defined Docker networks provide DNS-based service discovery.
Service names should be used instead of ephemeral container IP addresses.
Reverse proxies provide a single client-facing entry point.
Health endpoints should remain independent from downstream business dependencies.
Environment variables make service endpoints configurable.
Image versioning provides traceability and allows known-bad artifacts to remain identifiable.
Troubleshooting should isolate host networking, Docker networking, proxy routing, and application runtime as separate layers.
