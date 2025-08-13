# Use official PHP 8.2 with Apache
FROM php:8.2-apache

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_DOCUMENT_ROOT=/var/www/html
ENV MAUTIC_VERSION=7.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    libicu-dev \
    libonig-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    libc-client-dev \
    libkrb5-dev \
    libmagickwand-dev \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        intl \
        mbstring \
        zip \
        gd \
        xml \
        xsl \
        soap \
        bcmath \
        pdo \
        pdo_mysql \
        imap \
        opcache

# Install ImageMagick
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Install Node.js and npm for asset compilation
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Configure Apache
RUN a2enmod rewrite headers expires \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Set up PHP configuration for production
RUN { \
    echo 'memory_limit=512M'; \
    echo 'upload_max_filesize=256M'; \
    echo 'post_max_size=256M'; \
    echo 'max_execution_time=300'; \
    echo 'max_input_vars=3000'; \
    echo 'date.timezone=UTC'; \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.validate_timestamps=0'; \
} > /usr/local/etc/php/conf.d/mautic.ini

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Install Node dependencies and build assets
RUN npm ci --prefer-offline --no-audit \
    && npx patch-package \
    && npm run build

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/var \
    && chmod -R 775 /var/www/html/media \
    && chmod -R 775 /var/www/html/config

# Create directories for logs and cache
RUN mkdir -p /var/www/html/var/logs \
    && mkdir -p /var/www/html/var/cache \
    && mkdir -p /var/www/html/var/tmp \
    && chown -R www-data:www-data /var/www/html/var

# Set up supervisor for cron jobs
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/mautic-cron /etc/cron.d/mautic-cron
RUN chmod 0644 /etc/cron.d/mautic-cron \
    && crontab /etc/cron.d/mautic-cron

# Create Apache virtual host
COPY docker/mautic.conf /etc/apache2/sites-available/000-default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Start supervisor (which will manage Apache and cron)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
