# Digital Ocean Deployment Guide

## Prerequisites

1. **Digital Ocean Droplet** (Ubuntu 20.04+ recommended)
2. **SSH Key** configured for the droplet
3. **Local machine** with Node.js and npm installed

## Quick Deployment (Recommended)

### Step 1: Update the deployment script
```bash
# Edit simple-deploy.sh
nano simple-deploy.sh

# Update these variables:
DROPLET_IP="YOUR_ACTUAL_DROPLET_IP"    # e.g., "142.93.113.224"
DROPLET_USER="root"                    # or your username
SSH_KEY_PATH="~/.ssh/id_rsa"          # path to your SSH key
```

### Step 2: Make script executable and run
```bash
chmod +x simple-deploy.sh
./simple-deploy.sh
```

### Step 3: Access your app
- Open browser to `http://YOUR_DROPLET_IP`
- Your Astro app should be running!

## Manual Deployment (Alternative)

If you prefer manual steps:

### 1. Build the app locally
```bash
npm install
npm run build
```

### 2. Upload to droplet
```bash
# Upload dist folder contents
scp -r dist/* root@YOUR_DROPLET_IP:/var/www/html/
```

### 3. Configure nginx on droplet
```bash
# SSH into droplet
ssh root@YOUR_DROPLET_IP

# Install nginx
apt update && apt install -y nginx

# Create nginx config
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

# Restart nginx
systemctl restart nginx
systemctl enable nginx

# Configure firewall
ufw enable
ufw allow ssh
ufw allow 80
ufw allow 443
```

## Advanced Deployment (Full Features)

For production with PM2, SSL, and advanced features:

### 1. Update the full deployment script
```bash
# Edit deploy-to-digitalocean.sh
nano deploy-to-digitalocean.sh

# Update configuration section
```

### 2. Run full deployment
```bash
chmod +x deploy-to-digitalocean.sh
./deploy-to-digitalocean.sh
```

## SSL Certificate (Optional)

To add SSL certificate with Let's Encrypt:

```bash
# SSH into droplet
ssh root@YOUR_DROPLET_IP

# Install certbot
apt install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
certbot --nginx -d yourdomain.com

# Auto-renewal
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Troubleshooting

### Check if nginx is running
```bash
systemctl status nginx
```

### Check nginx logs
```bash
tail -f /var/log/nginx/error.log
```

### Test nginx configuration
```bash
nginx -t
```

### Restart nginx
```bash
systemctl restart nginx
```

### Check firewall status
```bash
ufw status
```

## File Structure on Droplet

```
/var/www/html/           # Static files (simple deployment)
├── index.html
├── _astro/
└── assets/

/var/www/one-remit-merchant/  # Full deployment
├── current/             # Current deployment
├── backup-*/           # Previous deployments
└── logs/               # Application logs
```

## Useful Commands

### View running processes
```bash
ps aux | grep nginx
```

### Check disk space
```bash
df -h
```

### Check memory usage
```bash
free -h
```

### Update system
```bash
apt update && apt upgrade -y
```

## Domain Configuration

If you have a domain name:

1. **Point domain to droplet IP** in your DNS provider
2. **Update nginx config** to include your domain:
   ```nginx
   server_name yourdomain.com www.yourdomain.com;
   ```
3. **Get SSL certificate** with certbot (see SSL section above)

## Backup Strategy

### Create backup script
```bash
#!/bin/bash
# backup.sh
tar -czf /root/backup-$(date +%Y%m%d).tar.gz /var/www/html
```

### Schedule daily backups
```bash
crontab -e
# Add: 0 2 * * * /root/backup.sh
```

## Performance Optimization

### Enable gzip compression
```nginx
# Add to nginx config
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

### Add caching headers
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify your droplet IP and SSH key
3. Ensure your droplet has sufficient resources (1GB RAM minimum)
4. Check Digital Ocean's firewall settings in their dashboard