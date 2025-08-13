# Mautic Coolify Deployment Guide

This Mautic installation is now ready for deployment on Coolify! 🚀

**Domain:** https://automate.augment.cfd

## 🎯 **Quick Deploy - Only 3 Required Variables!**

The Dockerfile includes defaults for your domain, so you only need to set these **3 essential variables** in Coolify:

#### **Required Environment Variables**
```
MAUTIC_DB_PASSWORD=your_secure_db_password
MYSQL_ROOT_PASSWORD=your_root_password  
MAUTIC_SECRET_KEY=your_32_character_secret_key
```

#### **Optional (if you want to override defaults)**
```
MAUTIC_MAILER_HOST=your_smtp_host
MAUTIC_MAILER_USER=your_smtp_username
MAUTIC_MAILER_PASSWORD=your_smtp_password
```

### ✅ **Already Set in Dockerfile:**
- ✅ Domain: `https://automate.augment.cfd`
- ✅ Admin email: `admin@augment.cfd`
- ✅ Admin password: `Maut1cR0cks!`
- ✅ Trusted hosts: `automate.augment.cfd`
- ✅ All other Mautic settings

### 2. Generate Secret Key

Generate a 32-character secret key:
```bash
openssl rand -hex 16
```

## 🚀 Deployment Steps

### Option 1: Direct Docker Deployment
1. Push your code to Git repository
2. In Coolify, create new application
3. Select "Docker Compose" deployment
4. Point to your repository
5. Set environment variables
6. Deploy!

### Option 2: Build from Dockerfile
1. In Coolify, create new application
2. Select "Dockerfile" deployment
3. Point to your repository
4. Set build context to root (`./`)
5. Set environment variables
6. Deploy!

## 🗄️ Database Setup

### Option 1: Use Coolify's Database Service
1. Create MariaDB/MySQL service in Coolify
2. Use the internal service name as `MAUTIC_DB_HOST`
3. Set the database credentials

### Option 2: External Database
1. Set up external MySQL/MariaDB server
2. Update `MAUTIC_DB_HOST` to external server
3. Ensure firewall allows connections

## 📁 Persistent Storage

The following directories need persistent volumes:
- `/var/www/html/media` - Media files and uploads
- `/var/www/html/var` - Cache, logs, and temporary files

Coolify will automatically handle these with the volume mounts defined in docker-compose.yml.

## 🔧 Post-Deployment

After successful deployment:

1. **Access Mautic**: Visit your domain
2. **Login**: Use the admin credentials you set
3. **Configure**: 
   - Set up your email settings
   - Configure your sender domain
   - Set up tracking domains
4. **Test**: Send a test email to verify everything works

## 🔍 Troubleshooting

### Check Logs
```bash
# In Coolify container terminal
tail -f /var/www/html/var/logs/prod.log
```

### Restart Services
```bash
# Restart Apache
supervisorctl restart apache2

# Clear cache
php bin/console cache:clear --env=prod
```

### Database Connection Issues
- Verify database credentials
- Check if database service is running
- Ensure database exists and user has proper permissions

## ⚙️ Environment Variables Reference

See `env.example` for complete list of available environment variables.

## 🔒 Security Notes

- Change default admin password immediately after first login
- Use strong database passwords
- Set up SSL/TLS certificates
- Configure trusted hosts properly
- Regularly update Mautic and dependencies

## 📞 Support

If you need help:
1. Check Coolify logs
2. Check Mautic logs in `/var/www/html/var/logs/`
3. Verify all environment variables are set correctly
4. Ensure database connectivity

Your Mautic instance is now ready for production! 🎉
