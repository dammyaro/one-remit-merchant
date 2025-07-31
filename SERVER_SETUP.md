# Server Setup Guide for Digital Ocean

## Quick Setup (Run on Server)

### Step 1: Connect to your droplet
```bash
ssh root@YOUR_DROPLET_IP
```

### Step 2: Download and run the server setup script
```bash
# Download the script
wget https://raw.githubusercontent.com/yourusername/yourrepo/main/server-deploy.sh

# Or if you have the files locally, upload the script first
# Then make it executable and run:
chmod +x server-deploy.sh
sudo ./server-deploy.sh
```

### Step 3: Upload your app files

**Option A: Use the upload script (from your local machine)**
```bash
# Edit upload-app.sh with your droplet IP
nano upload-app.sh

# Run the upload script
chmod +x upload-app.sh
./upload-app.sh
```

**Option B: Manual upload**
```bash
# Build locally
npm run build

# Upload dist folder
scp -r dist/* root@YOUR_DROPLET_IP:/var/www/html/

# Set permissions on server
ssh root@YOUR_DROPLET_IP "chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html"
```

**Option C: Direct on server**
```bash
# If you have git repository
git clone https://github.com/yourusername/one-remit-merchant.git
cd one-remit-merchant
npm install
npm run build
cp -r dist/* /var/www/html/
chown -R www-data:www-data /var/www/html
systemctl reload nginx
```

## What the server script does:

✅ **System Setup**
- Updates Ubuntu packages
- Installs Nginx, Node.js, npm
- Creates web directories

✅ **Security Configuration**
- Configures UFW firewall
- Sets proper file permissions
- Adds security headers

✅ **Web Server Setup**
- Configures Nginx for static files
- Enables gzip compression
- Sets up caching headers
- Configures SPA routing

✅ **Backup System**
- Creates backup directory
- Backs up existing files before deployment

## Manual Commands (if needed)

### Check services
```bash
# Check nginx status
systemctl status nginx

# Check if nginx is running
ps aux | grep nginx

# Test nginx config
nginx -t
```

### View logs
```bash
# Nginx error logs
tail -f /var/log/nginx/error.log

# Nginx access logs
tail -f /var/log/nginx/access.log

# System logs
journalctl -u nginx -f
```

### Restart services
```bash
# Restart nginx
systemctl restart nginx

# Reload nginx (without downtime)
systemctl reload nginx

# Enable nginx to start on boot
systemctl enable nginx
```

### File management
```bash
# View web files
ls -la /var/www/html/

# View backups
ls -la /var/backups/web/

# Check disk space
df -h

# Check file permissions
ls -la /var/www/html/
```

### Firewall management
```bash
# Check firewall status
ufw status

# Allow specific ports
ufw allow 80
ufw allow 443
ufw allow ssh

# Enable firewall
ufw enable
```

## SSL Certificate Setup (Optional)

### Install Certbot
```bash
apt install -y certbot python3-certbot-nginx
```

### Get SSL certificate (replace with your domain)
```bash
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Auto-renewal
```bash
# Test renewal
certbot renew --dry-run

# Add to crontab for auto-renewal
crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## Performance Optimization

### Enable additional compression
```bash
# Edit nginx config
nano /etc/nginx/sites-available/default

# Add to server block:
# gzip_comp_level 6;
# gzip_min_length 1000;
# gzip_proxied any;
```

### Monitor resources
```bash
# Check memory usage
free -h

# Check CPU usage
top

# Check disk usage
du -sh /var/www/html/
```

## Troubleshooting

### Common issues:

**1. Nginx won't start**
```bash
# Check config
nginx -t

# Check logs
journalctl -u nginx
```

**2. Permission denied errors**
```bash
# Fix permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```

**3. Site not accessible**
```bash
# Check if nginx is running
systemctl status nginx

# Check firewall
ufw status

# Check if port 80 is open
netstat -tlnp | grep :80
```

**4. SSL certificate issues**
```bash
# Check certificate status
certbot certificates

# Renew certificate
certbot renew
```

## Directory Structure

```
/var/www/html/              # Your web files
├── index.html
├── _astro/
└── assets/

/var/backups/web/           # Automatic backups
├── backup-20231201-120000.tar.gz
└── backup-20231202-120000.tar.gz

/etc/nginx/                 # Nginx configuration
├── sites-available/default
└── sites-enabled/default

/var/log/nginx/             # Nginx logs
├── access.log
└── error.log
```

## Quick Commands Reference

```bash
# Deploy new version
./upload-app.sh

# Check site status
curl -I http://localhost

# View real-time logs
tail -f /var/log/nginx/access.log

# Restart everything
systemctl restart nginx

# Check what's running on port 80
lsof -i :80
```