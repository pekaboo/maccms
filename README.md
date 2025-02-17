# PHP Docker Project

Docker environment for PHP development with Nginx, PHP-FPM, and MySQL.

## Requirements

- Docker
- Docker Compose

## Setup

1. Clone the repository
2. Create `src` directory and place your PHP application there
3. Run `chmod +x build.sh`
4. Execute `./build.sh`

## Services

- Nginx (Port 80)
- PHP-FPM 7.4
- MySQL 5.7 (Port 3306)

## Database Credentials

- Database: maccms
- Username: maccms
- Password: maccms_password
- Root Password: root

## Directory Structure

```
.
├── build.sh
├── docker-compose.yml
├── Dockerfile
├── nginx
│   └── conf.d
│       └── default.conf
└── src
    └── your-php-files
```
