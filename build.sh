#!/bin/bash
set -e

# Function for error handling
handle_error() {
    echo "Error occurred in build script at line $1"
    docker-compose logs
    exit 1
}

trap 'handle_error $LINENO' ERR

echo "Creating required directories..."
mkdir -p src/runtime
mkdir -p src/public/uploads
mkdir -p src/logs

echo "Setting initial permissions..."
chmod -R 777 src/runtime
chmod -R 777 src/public/uploads
chmod -R 777 src/logs

echo "Stopping existing containers..."
docker-compose down --remove-orphans

echo "Cleaning up old images..."
docker-compose rm -f

echo "Building new images..."
docker-compose build --no-cache

echo "Starting containers..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

echo "Checking service health..."
if ! docker-compose ps | grep -q "Up"; then
    echo "Services failed to start properly"
    docker-compose logs
    exit 1
fi

echo "Verifying database connection..."
if ! docker-compose exec php php -r "try {\$pdo = new PDO('mysql:host=mysql;dbname=maccms', 'maccms', 'maccms_password');} catch(PDOException \$e) {exit(1);}"
then
    echo "Database connection failed"
    docker-compose logs mysql
    exit 1
fi

echo "Checking PHP configuration..."
docker-compose exec php php -v
docker-compose exec php php -m

echo "Installation complete!"
echo "Your ThinkPHP application is now available at http://localhost"
docker-compose ps
