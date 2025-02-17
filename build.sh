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

echo "Creating required directories..."
for dir in "${BASE_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

echo "Setting directory permissions..."
# First ensure directories exist before setting permissions
for dir in "${BASE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
    fi
done

# Set write permissions for required directories
echo "Setting write permissions..."
chmod -R 777 logs 2>/dev/null || true
for dir in runtime upload static static_new; do
    if [ -d "src/$dir" ]; then
        chmod -R 777 "src/$dir" 2>/dev/null || true
    fi
done

echo "Setting base permissions for src directory..."
if [ -d "src" ]; then
    find src -type f -exec chmod 644 {} \; 2>/dev/null || true
    find src -type d -exec chmod 755 {} \; 2>/dev/null || true
fi

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
