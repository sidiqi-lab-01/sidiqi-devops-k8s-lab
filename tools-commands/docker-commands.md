# Docker Command Reference

## Version

Command:

    docker version

Usage:

Shows Docker client and server versions.

## Docker Information

Command:

    docker info

Usage:

Displays Docker runtime, storage, networking, and system information.

## List Running Containers

Command:

    docker ps

Usage:

Shows currently running containers.

## List All Containers

Command:

    docker ps -a

Usage:

Shows running and stopped containers.

## List Images

Command:

    docker image ls

Usage:

Displays locally stored container images and tags.

## Build Image

Command:

    docker build -t myapp:1.0 .

Usage:

Builds a Docker image and applies the specified tag.

## Run Container

Command:

    docker run -d --name myapp myapp:1.0

Usage:

Starts a container in detached mode.

## Publish Port

Command:

    docker run -d --name web -p 8080:80 nginx:alpine

Usage:

Maps host port 8080 to container port 80.

## Container Logs

Command:

    docker logs myapp

Usage:

Displays container logs.

## Follow Logs

Command:

    docker logs -f myapp

Usage:

Continuously follows container logs.

## Execute Command

Command:

    docker exec myapp id

Usage:

Runs a command inside a running container.

## Interactive Shell

Command:

    docker exec -it myapp sh

Usage:

Starts an interactive shell inside a container.

## Inspect Container

Command:

    docker inspect myapp

Usage:

Displays detailed container configuration and runtime metadata.

## Inspect Image

Command:

    docker image inspect myapp:1.0

Usage:

Displays detailed image metadata.

## Image History

Command:

    docker history myapp:1.0

Usage:

Shows image build layers.

## Stop Container

Command:

    docker stop myapp

Usage:

Gracefully stops a running container.

## Start Container

Command:

    docker start myapp

Usage:

Starts an existing stopped container.

## Restart Container

Command:

    docker restart myapp

Usage:

Restarts a container.

## Remove Container

Command:

    docker rm myapp

Usage:

Removes a stopped container.

## Remove Image

Command:

    docker image rm myapp:1.0

Usage:

Deletes a local Docker image.

## List Networks

Command:

    docker network ls

Usage:

Lists Docker networks.

## Inspect Network

Command:

    docker network inspect app-network

Usage:

Displays network configuration and attached containers.

## Compose Validation

Command:

    docker compose config --quiet

Usage:

Validates Docker Compose configuration.

## Compose Build

Command:

    docker compose build

Usage:

Builds images for Compose services.

## Compose Start

Command:

    docker compose up -d

Usage:

Starts the Compose application in detached mode.

## Compose Status

Command:

    docker compose ps

Usage:

Displays Compose container and health status.

## Compose Logs

Command:

    docker compose logs

Usage:

Displays logs from Compose services.

## Stop Compose Service

Command:

    docker compose stop db

Usage:

Stops a single service without removing it.

## Restart Compose Service

Command:

    docker compose restart api

Usage:

Restarts a specific service.

## Compose Down

Command:

    docker compose down

Usage:

Stops and removes Compose containers and networks.

## Resource Usage

Command:

    docker stats

Usage:

Displays live container CPU and memory usage.

## Disk Usage

Command:

    docker system df

Usage:

Displays Docker disk consumption.

## Runtime User

Command:

    docker exec myapp id

Usage:

Verifies which user the container process is running as.
