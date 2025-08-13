# Mautic Docker Deployment Guide

This guide explains how to deploy your Mautic marketing automation platform using Docker and Coolify.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- A Coolify instance (for cloud deployment)
- A domain name pointed to your server
- SSL certificate (handled automatically by Coolify)

### 1. Environment Configuration

Copy the example environment file and customize it:

```bash
cp env.example .env
```

**Critical Variables to Set:**

```bash
# Required: Your public domain
SITE_URL=https://yourdomain.com

# Required: Secure random string (32+ characters)
SECRET_KEY=your_very_secure_secret_key_32_characters_minimum

# Required: Database passwords
DB_PASSWORD=your_secure_database_password
DB_ROOT_PASSWORD=your_secure_root_password

# Required: Email configuration
MAILER_DSN=smtp://username:password@smtp.example.com:587
MAILER_FROM_EMAIL=noreply@yourdomain.com
```

### 2. Deploy with Coolify

1. **Create New Resource** in Coolify
2. **Select "Docker Compose"**
3. **Connect your Git repository**
4. **Set Environment Variables** from your `.env` file
5. **Deploy**

Coolify will automatically:
- Build the Docker containers
- Set up SSL certificates
- Configure networking
- Handle updates

### 3. Initial Setup

After deployment, access your Mautic instance and run the installer:

1. Visit `https://yourdomain.com`
2. Follow the installation wizard
3. The database connection should work automatically
4. Create your admin user

### 4. Configure Cron Jobs

The container automatically handles cron jobs for:
- ✅ Segment updates (hourly)
- ✅ Campaign processing (every 5 minutes)
- ✅ Email queue processing (every 5 minutes)
- ✅ Data imports (every 15 minutes)
- ✅ Webhook processing (every 5 minutes)
- ✅ Maintenance cleanup (daily)

## 📊 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mautic App    │    │   MariaDB       │    │     Redis       │
│   (Apache+PHP)  │◄──►│   Database      │    │    (Cache)      │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Configuration Options

### Email Configuration Examples

**SMTP:**
```bash
MAILER_DSN=smtp://username:password@smtp.example.com:587
```

**Gmail:**
```bash
MAILER_DSN=smtp://username:password@smtp.gmail.com:587
```

**SendGrid:**
```bash
MAILER_DSN=smtp://apikey:your_api_key@smtp.sendgrid.net:587
```

**Amazon SES:**
```bash
MAILER_DSN=smtp://ACCESS_KEY:SECRET_KEY@email-smtp.us-east-1.amazonaws.com:587
```

### Performance Optimization

For high-traffic sites, consider:

1. **Enable Redis Caching:**
```bash
CACHE_ADAPTER=cache.adapter.redis
REDIS_HOST=redis
REDIS_PORT=6379
```

2. **Use Async Message Processing:**
```bash
MESSENGER_DSN_EMAIL=redis://redis:6379
MESSENGER_DSN_HIT=redis://redis:6379
```

3. **Database Read Replicas:**
```bash
DB_HOST_RO=db-replica-host
```

## 🛡️ Security Recommendations

1. **Use Strong Passwords:**
   - Database passwords (20+ characters)
   - Secret key (32+ characters)

2. **Configure Trusted Hosts:**
```bash
TRUSTED_HOSTS=yourdomain.com,www.yourdomain.com
```

3. **Set Trusted Proxies** (if behind load balancer):
```bash
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

4. **Enable Secure Cookies:**
```bash
COOKIE_SECURE=true
COOKIE_HTTPONLY=true
```

## 🔍 Monitoring & Logs

### View Application Logs
```bash
docker-compose logs -f mautic
```

### View Database Logs
```bash
docker-compose logs -f db
```

### Access Container Shell
```bash
docker-compose exec mautic bash
```

### Check Cron Jobs Status
```bash
docker-compose exec mautic crontab -l -u www-data
```

## 🚨 Troubleshooting

### Common Issues

**1. Site not loading:**
- Check `SITE_URL` matches your domain exactly
- Verify SSL certificate is valid
- Check Coolify logs

**2. Database connection errors:**
- Verify database passwords in `.env`
- Check if database container is running
- Wait for database initialization (first startup takes time)

**3. Email not sending:**
- Test SMTP credentials manually
- Check `MAILER_DSN` format
- Verify firewall allows outbound SMTP

**4. Cron jobs not running:**
- Check supervisor logs: `docker-compose exec mautic supervisorctl status`
- Verify cron file permissions
- Check system clock synchronization

### Useful Commands

**Clear Mautic Cache:**
```bash
docker-compose exec mautic php bin/console cache:clear --env=prod
```

**Run Mautic Commands:**
```bash
docker-compose exec mautic php bin/console mautic:segments:update
docker-compose exec mautic php bin/console mautic:campaigns:update
```

**Database Backup:**
```bash
docker-compose exec db mysqldump -u root -p mautic > backup.sql
```

## 📈 Scaling

For high-traffic deployments:

1. **Horizontal Scaling:** Run multiple Mautic containers behind a load balancer
2. **Database Optimization:** Use read replicas and connection pooling
3. **Cache Optimization:** Implement Redis cluster
4. **CDN:** Serve static assets via CDN
5. **Queue Workers:** Use dedicated containers for message processing

## 🔄 Updates

To update Mautic:

1. **Backup your data first**
2. **Update via Coolify** (rebuilds containers with latest code)
3. **Run database migrations** if needed:
```bash
docker-compose exec mautic php bin/console doctrine:migrations:migrate --no-interaction
```

## 📞 Support

- **Mautic Documentation:** https://docs.mautic.org
- **Community Forum:** https://forum.mautic.org
- **GitHub Issues:** https://github.com/mautic/mautic

---

## 🏷️ Environment Variables Reference

See `env.example` for a complete list of all available environment variables and their descriptions.

**Most Important Variables:**
- `SITE_URL` - Your public domain
- `SECRET_KEY` - Encryption key
- `DB_PASSWORD` - Database password
- `MAILER_DSN` - Email configuration
- `TRUSTED_HOSTS` - Security setting
