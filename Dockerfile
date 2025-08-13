# Mautic Production Dockerfile
FROM php:8.2-apache

# Set environment variables
ENV APACHE_DOCUMENT_ROOT=/var/www/html
ENV COMPOSER_ALLOW_SUPERUSER=1

# Set Mautic default environment variables (can be overridden)
ENV APP_ENV=prod
ENV APP_DEBUG=0
ENV MAUTIC_SITE_URL=https://automate.augment.cfd
ENV MAUTIC_REQUEST_CONTEXT_HOST=automate.augment.cfd
ENV MAUTIC_REQUEST_CONTEXT_SCHEME=https
ENV MAUTIC_TRUSTED_HOSTS=automate.augment.cfd
ENV MAUTIC_ADMIN_USERNAME=admin
ENV MAUTIC_ADMIN_PASSWORD=Maut1cR0cks!
ENV MAUTIC_ADMIN_EMAIL=admin@augment.cfd
ENV MAUTIC_ADMIN_FIRSTNAME=Admin
ENV MAUTIC_ADMIN_LASTNAME=User
ENV MAUTIC_MAILER_TRANSPORT=smtp
ENV MAUTIC_MAILER_HOST=smtp.mailtrap.io
ENV MAUTIC_MAILER_PORT=587
ENV MAUTIC_MAILER_USER=testuser123
ENV MAUTIC_MAILER_PASSWORD=testpass123
ENV MAUTIC_MAILER_ENCRYPTION=tls
ENV MAUTIC_MAILER_AUTH_MODE=login
ENV MAUTIC_SECRET_KEY=abc123def456ghi789jkl012mno345pq
ENV MAUTIC_DB_HOST=db
ENV MAUTIC_DB_PORT=3306
ENV MAUTIC_DB_NAME=mautic
ENV MAUTIC_DB_USER=mautic
ENV MAUTIC_DB_PASSWORD=testdbpass123
ENV MYSQL_ROOT_PASSWORD=rootpass123
ENV MAUTIC_LOCALE=en_US
ENV MAUTIC_IMAGE_PATH=media/images
ENV MAUTIC_MEDIA_PATH=media
ENV MAUTIC_LOG_PATH=var/logs
ENV MAUTIC_MAX_LOG_FILES=7
ENV MAUTIC_TWIG_CACHE_DIR=var/cache/prod/twig

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libicu-dev \
    libpq-dev \
    libxrender1 \
    libfontconfig1 \
    libxext6 \
    wget \
    cron \
    supervisor \
    libc-client2007e-dev \
    libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        intl \
        opcache \
        imap

# Enable Apache modules
RUN a2enmod rewrite headers expires deflate ssl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install dependencies and build assets
RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && npm ci --only=production \
    && npm run build \
    && rm -rf node_modules

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/var \
    && chmod -R 777 /var/www/html/media

# Create necessary directories
RUN mkdir -p /var/www/html/var/cache \
    && mkdir -p /var/www/html/var/logs \
    && mkdir -p /var/www/html/var/spool \
    && mkdir -p /var/www/html/var/tmp \
    && mkdir -p /var/www/html/media/files \
    && mkdir -p /var/www/html/media/images \
    && chown -R www-data:www-data /var/www/html/var \
    && chown -R www-data:www-data /var/www/html/media

# Copy Apache configuration
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf

# Copy entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
