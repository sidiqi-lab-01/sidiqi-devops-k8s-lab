# Container Image Versioning and Security

## Overview

This lab implements container image versioning, least-privilege execution,
image inspection, vulnerability scanning, and automated security validation
for the Docker Compose microservices application.

The goal is to demonstrate a repeatable DevOps/SRE image lifecycle without
overwriting known-good container images.

## Architecture

The Docker Compose application contains:

- Frontend: Nginx
- API: Python / Flask / Gunicorn
- Users: Python / Flask / Gunicorn
- Orders: Python / Flask / Gunicorn
- Database: PostgreSQL

For this security iteration, the API, Users, and Orders services were
hardened from version 1.0 to version 1.1.

The frontend remains on version 1.0 for this iteration.

## Image Versioning Strategy

Version 1.0 images were retained rather than overwritten.

New hardened images were built as:

- sidiqi-compose-api:1.1
- sidiqi-compose-users:1.1
- sidiqi-compose-orders:1.1

The previous images remain available as:

- sidiqi-compose-api:1.0
- sidiqi-compose-users:1.0
- sidiqi-compose-orders:1.0

Keeping explicit versions provides traceability and allows controlled
rollback to a previously known image.

## Security Baseline

The original 1.0 Python images did not define an explicit Docker USER.

Runtime validation showed that the containers executed as UID 0 (root).

Example:

docker exec sidiqi-compose-api id

The baseline container returned root.

This represented unnecessary privilege for an application service.

## Least-Privilege Hardening

A dedicated system user and group were added to each Python service image.

Example Dockerfile pattern:

RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup appuser

COPY --chown=appuser:appgroup app.py .

USER appuser

This ensures the application process does not require root privileges.

## Runtime Validation

After deployment of version 1.1, the services ran as:

uid=100(appuser)
gid=101(appgroup)

The API, Users, and Orders containers all successfully operated as the
dedicated application user.

Docker inspection also confirmed that the running containers referenced
the 1.1 image versions.

## Functional Validation

After hardening, the application remained operational.

Validated endpoints included:

- /api/health
- /api/users
- /api/orders

The API remained healthy, the Users service returned expected user data,
and the Orders service continued retrieving PostgreSQL-backed order data.

This demonstrated that root privileges were not required for normal
application functionality.

## Privilege Test

A negative security test attempted to create a file under /root from the
hardened API container.

The operation failed with:

Permission denied

The command returned a non-zero exit status.

A second test created a temporary file under /tmp successfully.

This demonstrated that the application retained the permissions required
for normal operation while being prevented from writing to root-owned
locations.

## Image Inspection

Docker image history was compared between versions 1.0 and 1.1.

Version 1.1 introduced security-specific layers including:

- creation of appgroup
- creation of appuser
- COPY --chown
- USER appuser

Version 1.0 contained no explicit USER instruction.

Docker image inspection was also used to validate:

- image identity
- configured runtime user
- working directory
- exposed ports
- runtime command

## Vulnerability Awareness

Trivy was used to scan the container image for known vulnerabilities.

Security scanning and least-privilege execution address different risks.

Vulnerability scanning identifies known vulnerabilities in operating
system packages and application dependencies.

Running as a non-root user reduces the potential impact if a vulnerable
application or dependency is successfully exploited.

Therefore, an image can have the same vulnerability count before and
after a USER hardening change while still having an improved security
posture.

## Automated Security Validation

A reusable validation script was created:

scripts/docker/validate-image-security.sh

The script validates:

- image identity
- configured runtime user
- working directory
- exposed ports
- image history
- HIGH and CRITICAL vulnerability findings when Trivy is available

The script rejects images that run with the Docker root default.

Example:

./scripts/docker/validate-image-security.sh sidiqi-compose-api:1.1

The hardened image passes the non-root policy.

The legacy 1.0 image fails the policy because no explicit non-root USER
is configured.

This demonstrates how container security requirements can be converted
from manual checks into repeatable automation suitable for CI/CD.

## Rollback Strategy

The 1.0 images were intentionally retained.

If a 1.1 deployment introduced an application regression, Compose could
be changed back to the known previous version and the affected service
recreated.

This is preferable to repeatedly overwriting a mutable tag because
explicit versions improve:

- traceability
- rollback capability
- auditability
- troubleshooting
- release management

Production environments should additionally use immutable registry
digests and controlled release promotion.

## DevOps/SRE Application

This implementation demonstrates several production engineering
principles:

1. Build a known baseline before changing security controls.
2. Create a new image version instead of overwriting the previous image.
3. Run application processes with least privilege.
4. Validate security controls at runtime rather than trusting the
   Dockerfile alone.
5. Perform negative security tests.
6. Scan images for known vulnerabilities.
7. Automate security validation.
8. Preserve rollback capability.
9. Validate application functionality after security changes.
10. Document implementation and troubleshooting evidence.

These controls can later be integrated into CI/CD so insecure images are
prevented from progressing through the deployment pipeline.

## Result

The API, Users, and Orders services were successfully upgraded from
version 1.0 to hardened version 1.1 images.

The services operate as a dedicated non-root application user while
maintaining application functionality.

The previous 1.0 images remain available for rollback, vulnerability
awareness was added with Trivy, and repeatable security validation was
implemented through repository automation.
