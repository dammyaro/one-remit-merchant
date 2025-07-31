#!/bin/bash

# Server-side deployment script for Digital Ocean droplet
# Run this script directly on your droplet

set -e

# Configuration
APP_NAME="one-remit-merchant"
WEB_DIR="/var/www/html"
BACKUP_DIR="/var/backups/web"
PORT="80"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting server-side deployment...${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (use sudo)"
    exit 1
fi

# Update system packages
echo -e "${BLUE}📦 Updating system packages...${NC}"
apt update && apt upgrade -y
print_status "System updated"

# Install required packages
echo -e "${BLUE}🔧 Installing required packages...${NC}"
apt install -y nginx curl wget unzip git nodejs npm
print_status "Packages installed"

# Create backup directory
echo -e "${BLUE}📁 Setting up directories...${NC}"
mkdir -p "$BACKUP_DIR"
mkdir -p "$WEB_DIR"

# Backup existing website if it exists
if [ "$(ls -A $WEB_DIR)" ]; then
    echo -e "${BLUE}💾 Backing up existing website...${NC}"
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$WEB_DIR" .
    print_status "Backup created: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
    
    # Clear web directory
    rm -rf "$WEB_DIR"/*
fi

# Clone or download the repository
echo -e "${BLUE}📥 Getting application files...${NC}"
cd /tmp

# Option 1: If you have the files locally, you can copy them
# Option 2: Clone from git repository (uncomment if needed)
# git clone https://github.com/yourusername/one-remit-merchant.git
# cd one-remit-merchant

# Option 3: Download from URL (uncomment and update URL if needed)
# wget -O app.zip "YOUR_DOWNLOAD_URL"
# unzip app.zip
# cd one-remit-merchant

# For now, we'll assume files are already on the server
echo -e "${YELLOW}📋 Please ensure your app files are in the current directory${NC}"
echo -e "${YELLOW}   or update this script to download/clone from your source${NC}"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    print_warning "package.json not found. Creating basic structure..."
    
    # Create a basic structure for static files
    mkdir -p static-app
    cd static-app
    
    # Create basic HTML files (you can replace these with your actual files)
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">
    <title>One Remit Merchant - Deployed</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #0a0a0a; color: white; }
        .container { max-width: 800px; margin: 0 auto; text-align: center; }
        .status { background: #1a1a1a; padding: 20px; border-radius: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 One Remit Merchant</h1>
        <div class="status">
            <h2>✅ Successfully Deployed to Digital Ocean!</h2>
            <p>Your application is now running on this server.</p>
            <p>Upload your built Astro files to replace this placeholder.</p>
        </div>
    </div>
</body>
</html>
EOF
    
    print_warning "Created placeholder HTML. Replace with your actual app files."
else
    # Build the application if package.json exists
    echo -e "${BLUE}🏗️  Building application...${NC}"
    npm install
    npm run build
    print_status "Application built successfully"
    
    # Use the built files
    if [ -d "dist" ]; then
        cd dist
    fi
fi

# Copy files to web directory
echo -e "${BLUE}📋 Deploying files to web directory...${NC}"
cp -r * "$WEB_DIR/"
print_status "Files deployed to $WEB_DIR"

# Set proper permissions
chown -R www-data:www-data "$WEB_DIR"
chmod -R 755 "$WEB_DIR"
print_status "Permissions set"

# Configure Nginx
echo -e "${BLUE}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm;
    
    server_name _;
    
    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security: deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Test Nginx configuration
nginx -t
if [ $? -eq 0 ]; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# Restart and enable Nginx
systemctl restart nginx
systemctl enable nginx
print_status "Nginx configured and started"

# Configure firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
print_status "Firewall configured"

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')

# Final status check
echo -e "${BLUE}🔍 Performing health check...${NC}"
sleep 2

if systemctl is-active --quiet nginx; then
    print_status "Nginx is running"
else
    print_error "Nginx is not running"
fi

if curl -f -s "http://localhost" > /dev/null; then
    print_status "Application is responding"
else
    print_warning "Application might not be responding correctly"
fi

# Display completion message
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📱 Your application is now available at:${NC}"
echo -e "   🌐 http://$SERVER_IP"
echo -e "   🌐 http://localhost (from server)"

echo -e "${BLUE}📋 Useful commands:${NC}"
echo -e "   Check Nginx status: ${YELLOW}systemctl status nginx${NC}"
echo -e "   View Nginx logs: ${YELLOW}tail -f /var/log/nginx/error.log${NC}"
echo -e "   Restart Nginx: ${YELLOW}systemctl restart nginx${NC}"
echo -e "   View website files: ${YELLOW}ls -la $WEB_DIR${NC}"
echo -e "   View backups: ${YELLOW}ls -la $BACKUP_DIR${NC}"

echo -e "${BLUE}🔧 To update your app:${NC}"
echo -e "   1. Upload new files to $WEB_DIR"
echo -e "   2. Run: ${YELLOW}systemctl reload nginx${NC}"

echo -e "${GREEN}✨ Server deployment completed!${NC}"