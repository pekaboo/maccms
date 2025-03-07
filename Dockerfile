FROM php:7.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    soap \
    opcache

# Configure PHP
COPY docker/php/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Create necessary directories
RUN mkdir -p /var/www/html/runtime \
    && mkdir -p /var/www/html/upload \
    && mkdir -p /var/www/html/static \
    && mkdir -p /var/www/html/static_new \
    && chown -R www-data:www-data /var/www/html

# Copy existing application directory
COPY --chown=www-data:www-data ./src /var/www/html/

# Install composer dependencies
RUN composer install --no-interaction --optimize-autoloader --no-dev || true

# Set final permissions
RUN find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R 777 /var/www/html/runtime \
    && chmod -R 777 /var/www/html/upload \
    && chmod -R 777 /var/www/html/static \
    && chmod -R 777 /var/www/html/static_new
