#!/bin/bash

# Stop all containers
docker-compose down

# Remove old images
docker-compose rm -f

# Build new images
docker-compose build

# Start containers
docker-compose up -d

# Show container status
docker-compose ps
