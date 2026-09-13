# Docker Compose Multi-Container Application

## Objective

Build and validate a separate multi-container microservices application using Docker Compose.

This implementation demonstrates:

- Docker Compose orchestration
- Service discovery
- Container networking
- Health checks
- Service dependencies
- PostgreSQL integration
- Persistent storage
- Reverse proxy routing
- Failure isolation
- Dependency troubleshooting
- Recovery validation

This work supports GitHub Issue #75.

## Architecture

```text
Browser
   |
   | TCP 8180
   v
Frontend / Nginx
   |
   | Docker Compose DNS
   v
API :5000
   |
   +------> Users :5001
   |
   +------> Orders :5002
                  |
                  | Docker Compose DNS
                  v
              PostgreSQL :5432
Only the frontend is published to the EC2 host.

The API, Users, Orders, and PostgreSQL services remain internal to the Compose network.

Application Isolation

The existing manually deployed Docker application from Issue #74 was retained unchanged.

Existing application
Frontend :8080
API      :5000
Users    :5001
Orders   :5002
Docker Compose application
Frontend :8180
API      internal :5000
Users    internal :5001
Orders   internal :5002
Database internal :5432

Both stacks were validated running simultaneously on the same Docker host.

Application Structure
docker/compose-app/
├── .env.example
├── .gitignore
├── compose.yaml
├── api/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .dockerignore
├── users/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .dockerignore
├── orders/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .dockerignore
├── frontend/
│   ├── index.html
│   ├── default.conf
│   ├── Dockerfile
│   └── .dockerignore
└── database/
    └── init.sql
Services
Frontend

Nginx provides the external application entry point.

Published port:

8180 -> container port 80

Nginx forwards API requests using the Docker Compose service name:

http://api:5000

This demonstrates service discovery without hard-coded container IP addresses.

API

The API service provides:

/
/health
/api/health
/api/users
/api/orders

The API communicates with downstream services using Compose DNS:

http://users:5001
http://orders:5002
Users

The Users service exposes:

/
/health
/users

Sample users:

Sidiqi1
Sidiqi2
Sidiqi3
Orders

The Orders service exposes:

/
/health
/orders

The service communicates with PostgreSQL using:

DB_HOST=db
DB_PORT=5432

The database hostname is the Docker Compose service name rather than an IP address.

PostgreSQL

PostgreSQL stores order data.

The database is initialized from:

database/init.sql

Sample orders:

Laptop   shipped
Monitor  processing
Keyboard delivered

A named Docker volume provides persistent database storage.

Docker Compose Networking

A dedicated bridge network is used:

sidiqi-compose-network

Services communicate using Compose service names:

frontend -> api
api -> users
api -> orders
orders -> db

This removes dependence on ephemeral container IP addresses.

Persistent Storage

PostgreSQL uses the named volume:

sidiqi-compose-postgres-data

The volume allows database data to survive normal container recreation.

Configuration Management

Application database configuration is provided through environment variables.

The local environment file is:

.env

It is excluded from Git.

A safe example file is committed:

.env.example

Example:

POSTGRES_DB=ordersdb
POSTGRES_USER=ordersuser
POSTGRES_PASSWORD=change-me

No operational database password is stored in the committed Compose configuration or application source.

Health Checks

Health checks were configured for all five services.

PostgreSQL

PostgreSQL readiness is checked with:

pg_isready
Users
http://127.0.0.1:5001/health
Orders
http://127.0.0.1:5002/health

The Orders health check also validates database connectivity.

API
http://127.0.0.1:5000/health
Frontend

Nginx is checked through local HTTP access.

Final state:

sidiqi-compose-frontend   healthy
sidiqi-compose-api        healthy
sidiqi-compose-orders     healthy
sidiqi-compose-db         healthy
sidiqi-compose-users      healthy
Service Dependencies

Docker Compose dependencies are configured using health-based startup conditions.

Dependency flow:

PostgreSQL healthy
        |
        v
Orders healthy

Users healthy
      \   /
       \ /
       API healthy
           |
           v
     Frontend healthy

This prevents dependent services from being considered ready before required upstream services are healthy.

Validation

The Compose configuration was validated with:

docker compose config --quiet

Result:

Compose configuration: VALID

Services were started with:

docker compose up -d

All five services reached a healthy state.

Frontend
curl -I http://127.0.0.1:8180

Result:

HTTP/1.1 200 OK
API health
curl http://127.0.0.1:8180/api/health

Result:

{"service":"compose-api","status":"healthy"}
Users
curl http://127.0.0.1:8180/api/users

Returned:

Sidiqi1
Sidiqi2
Sidiqi3
Orders
curl http://127.0.0.1:8180/api/orders

Returned order records stored in PostgreSQL.

Browser Validation

The Compose application was also validated through a browser using the EC2 public endpoint on TCP port 8180.

The browser successfully accessed:

/
 /api/health
 /api/users
 /api/orders

This validated the full external request path:

Browser
   |
   v
EC2 :8180
   |
   v
Nginx
   |
   v
API
   |
   +----> Users
   |
   +----> Orders
             |
             v
          PostgreSQL
Failure Test

A controlled PostgreSQL failure was introduced:

docker compose stop db

The application behavior was then tested.

API health
/api/health

remained healthy.

Users
/api/users

continued serving requests successfully.

Orders
/api/orders

returned:

HTTP/1.1 503 SERVICE UNAVAILABLE

The Orders container transitioned to:

unhealthy

while unrelated services remained healthy.

This demonstrated dependency isolation and partial application availability.

Recovery Test

PostgreSQL was restored:

docker compose start db

PostgreSQL returned to a healthy state, followed by the Orders service.

The Orders endpoint then recovered successfully without rebuilding or redeploying the entire application stack.

Troubleshooting Lessons
Compose Configuration Location

Running Docker Compose from a directory without compose.yaml produced:

no configuration file provided: not found

Resolution:

cd docker/compose-app
docker compose ps

Alternatively, the configuration can be provided explicitly with:

docker compose -f docker/compose-app/compose.yaml ps
Dependency Failure Isolation

Stopping PostgreSQL affected the Orders path but did not take down the Users service or API health endpoint.

This demonstrated that distributed applications can experience partial failures while maintaining unrelated functionality.

Health Versus Process State

A container can remain running while becoming unhealthy.

The Orders container remained up but changed to:

unhealthy

because its database dependency was unavailable.

This demonstrates why container process status alone is insufficient for production monitoring.

Production Considerations

For a production environment, additional improvements would include:

Use AWS Secrets Manager, Vault, Kubernetes Secrets, or another centralized secret-management system.
Avoid fixed container names when horizontal scaling is required.
Use TLS for external traffic.
Add authentication and authorization.
Add centralized logging and metrics.
Add tracing between microservices.
Add database backups and high availability.
Add resource limits and reservations.
Add CI/CD image scanning.
Pin production image versions or digests.
Add automated integration and failure testing.
Interview Relevance

This lab demonstrates the ability to:

Convert manually managed containers into declarative orchestration.
Design service dependencies.
Configure health-based startup behavior.
Use service discovery instead of IP addresses.
Integrate application services with a SQL database.
Isolate internal services from external exposure.
Diagnose dependency failures.
Preserve partial service availability.
Validate recovery without a full redeployment.
Manage application configuration without committing operational secrets.

A concise interview explanation:

I built a separate five-service Docker Compose application containing Nginx, an API, Users and Orders microservices, and PostgreSQL. I used Compose DNS for service discovery, health checks for readiness, dependency conditions for startup sequencing, and a named volume for persistence. I intentionally stopped PostgreSQL and confirmed that Orders became unhealthy and returned a 503 while Users and the API health endpoint remained available. After restoring PostgreSQL, the dependent service recovered automatically. I also kept the original manually deployed stack running simultaneously to demonstrate application isolation and the transition from imperative container management to declarative orchestration.
