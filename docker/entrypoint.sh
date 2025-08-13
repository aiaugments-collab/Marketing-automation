#!/bin/bash

set -e

# Function to wait for database
wait_for_db() {
    echo "Waiting for database connection..."
    until php -r "
        try {
            \$pdo = new PDO('mysql:host='.\$_ENV['MAUTIC_DB_HOST'].';port='.\$_ENV['MAUTIC_DB_PORT'], \$_ENV['MAUTIC_DB_USER'], \$_ENV['MAUTIC_DB_PASSWORD']);
            echo 'Database connected successfully\n';
            exit(0);
        } catch (PDOException \$e) {
            echo 'Database connection failed: ' . \$e->getMessage() . '\n';
            exit(1);
        }
    "; do
        echo "Database not ready, waiting 5 seconds..."
        sleep 5
    done
}

# Wait for database if DB_HOST is set
if [ ! -z "$MAUTIC_DB_HOST" ]; then
    wait_for_db
fi

# Set proper ownership
chown -R www-data:www-data /var/www/html/var
chown -R www-data:www-data /var/www/html/media

# Clear and warm up cache
if [ -d "/var/www/html/var/cache" ]; then
    rm -rf /var/www/html/var/cache/*
fi

# Run as www-data user for Mautic commands
su-exec www-data php bin/console cache:clear --env=prod --no-debug
su-exec www-data php bin/console cache:warmup --env=prod --no-debug

# Install Mautic if not already installed
if [ ! -f "/var/www/html/app/config/local.php" ]; then
    echo "Installing Mautic..."
    su-exec www-data php bin/console mautic:install --force \
        --db_driver=pdo_mysql \
        --db_host="${MAUTIC_DB_HOST}" \
        --db_port="${MAUTIC_DB_PORT:-3306}" \
        --db_name="${MAUTIC_DB_NAME}" \
        --db_user="${MAUTIC_DB_USER}" \
        --db_password="${MAUTIC_DB_PASSWORD}" \
        --db_table_prefix="${MAUTIC_DB_PREFIX:-}" \
        --admin_username="${MAUTIC_ADMIN_USERNAME:-admin}" \
        --admin_password="${MAUTIC_ADMIN_PASSWORD}" \
        --admin_email="${MAUTIC_ADMIN_EMAIL}" \
        --admin_firstname="${MAUTIC_ADMIN_FIRSTNAME:-Admin}" \
        --admin_lastname="${MAUTIC_ADMIN_LASTNAME:-User}" \
        --mailer_transport="${MAUTIC_MAILER_TRANSPORT:-smtp}" \
        --mailer_host="${MAUTIC_MAILER_HOST:-localhost}" \
        --mailer_port="${MAUTIC_MAILER_PORT:-587}" \
        --mailer_user="${MAUTIC_MAILER_USER:-}" \
        --mailer_password="${MAUTIC_MAILER_PASSWORD:-}" \
        --mailer_encryption="${MAUTIC_MAILER_ENCRYPTION:-tls}" \
        --mailer_auth_mode="${MAUTIC_MAILER_AUTH_MODE:-login}"
    
    echo "Mautic installation completed!"
else
    echo "Mautic already installed, running migrations..."
    su-exec www-data php bin/console doctrine:migrations:migrate --no-interaction
fi

# Generate assets if needed
if [ ! -d "/var/www/html/media/css" ] || [ ! -d "/var/www/html/media/js" ]; then
    echo "Generating assets..."
    su-exec www-data php bin/console mautic:assets:generate --env=prod
fi

# Start cron daemon for Mautic tasks
service cron start

# Setup Mautic cron jobs
echo "*/5 * * * * www-data /usr/local/bin/php /var/www/html/bin/console mautic:segments:update --env=prod > /dev/null 2>&1" >> /etc/crontab
echo "*/5 * * * * www-data /usr/local/bin/php /var/www/html/bin/console mautic:campaigns:trigger --env=prod > /dev/null 2>&1" >> /etc/crontab
echo "*/5 * * * * www-data /usr/local/bin/php /var/www/html/bin/console mautic:campaigns:rebuild --env=prod > /dev/null 2>&1" >> /etc/crontab
echo "*/10 * * * * www-data /usr/local/bin/php /var/www/html/bin/console mautic:emails:send --env=prod > /dev/null 2>&1" >> /etc/crontab
echo "0 2 * * * www-data /usr/local/bin/php /var/www/html/bin/console mautic:maintenance:cleanup --days-old=7 --env=prod > /dev/null 2>&1" >> /etc/crontab

echo "Mautic is ready! Starting services..."

# Execute the main command
exec "$@"
