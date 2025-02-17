#!/bin/bash
set -e

# Function for error handling
handle_error() {
    echo "Error occurred in build script at line $1"
    docker-compose logs
    exit 1
}

trap 'handle_error $LINENO' ERR

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Warning: Running as root, checking directory permissions..."
fi

# Create base directories if they don't exist
BASE_DIRS=(
    "src/runtime"
    "src/upload"
    "src/static"
    "src/static_new"
    "logs/nginx"
    "logs/php"
    "logs/mysql"
)

for dir in "${BASE_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# Set proper permissions
echo "Setting directory permissions..."
find src/runtime -type d -exec chmod 755 {} \;
find src/upload -type d -exec chmod 755 {} \;
find src/static -type d -exec chmod 755 {} \;
find src/static_new -type d -exec chmod 755 {} \;
find logs -type d -exec chmod 755 {} \;

# Ensure write permissions for runtime directories
chmod -R 777 src/runtime
chmod -R 777 src/upload
chmod -R 777 src/static
chmod -R 777 src/static_new
chmod -R 777 src/logs
chmod -R 777 logs

# 删除创建测试文件的部分
# echo "Creating test file..."
# echo "<?php phpinfo(); ?>" > src/public/index.php
# chmod 644 src/public/index.php

echo "Setting permissions..."
chmod -R 755 src
find src -type f -exec chmod 644 {} \;
find src -type d -exec chmod 755 {} \;
chmod -R 777 src/runtime
chmod -R 777 src/upload
chmod -R 777 src/static
chmod -R 777 src/static_new

echo "Stopping existing containers..."
docker-compose down --remove-orphans || true

echo "Cleaning up old images..."
docker-compose rm -f || true

echo "Pulling latest base images..."
docker-compose pull

echo "Building new images..."
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build --no-cache

echo "Starting containers..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

# Check container health
echo "Checking service health..."
if ! docker-compose ps | grep -q "Up"; then
    echo "Services failed to start properly"
    docker-compose logs
    exit 1
fi

# Verify services are responding
echo "Verifying services..."
docker-compose exec -T php php -v || (echo "PHP service not responding" && exit 1)
docker-compose exec -T mysql mysqladmin -u maccms -pmaccms_password ping || (echo "MySQL service not responding" && exit 1)

echo "Checking Nginx configuration..."
docker-compose exec web nginx -t

echo "Checking directory permissions..."
docker-compose exec web ls -la /var/www/html/public
docker-compose exec php ls -la /var/www/html/public

echo "Installation complete!"
echo "Your ThinkPHP application is now available at http://localhost"
docker-compose ps
