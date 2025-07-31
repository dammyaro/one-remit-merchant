#!/bin/bash

# Deploy application files on server
# Run this script ON THE SERVER where the Astro files are already present

set -e

# Configuration
WEB_DIR="/var/www/html"
BACKUP_DIR="/var/backups/web"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploying app files from current directory...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script as root (use sudo)${NC}"
    exit 1
fi

# Check if package.json exists in current directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found in current directory${NC}"
    echo -e "${YELLOW}💡 Make sure you're in the directory with your Astro project files${NC}"
    exit 1
fi

# Check if node and npm are installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
fi

# Build the app
echo -e "${BLUE}🏗️  Building Astro app...${NC}"
npm install
npm run build

# Check if build was successful
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Build failed - dist directory not found${NC}"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup existing files if web directory exists and has content
if [ -d "$WEB_DIR" ] && [ "$(ls -A $WEB_DIR 2>/dev/null)" ]; then
    echo -e "${BLUE}💾 Creating backup of existing files...${NC}"
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$WEB_DIR" . 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR/$BACKUP_NAME.tar.gz${NC}"
fi

# Create web directory if it doesn't exist
mkdir -p "$WEB_DIR"

# Clear existing web files
echo -e "${BLUE}🗑️  Clearing existing web files...${NC}"
rm -rf "$WEB_DIR"/*

# Copy built files to web directory
echo -e "${BLUE}📋 Deploying new files...${NC}"
cp -r dist/* "$WEB_DIR/"

# Set proper permissions
echo -e "${BLUE}🔐 Setting permissions...${NC}"
chown -R www-data:www-data "$WEB_DIR"
chmod -R 755 "$WEB_DIR"

# Check if nginx is installed and running
if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx; then
        echo -e "${BLUE}🔄 Reloading Nginx...${NC}"
        systemctl reload nginx
    else
        echo -e "${YELLOW}⚠️  Nginx is installed but not running. Starting it...${NC}"
        systemctl start nginx
        systemctl enable nginx
    fi
else
    echo -e "${YELLOW}⚠️  Nginx not found. Installing and configuring...${NC}"
    apt update
    apt install -y nginx
    
    # Create basic nginx config
    cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
    
    systemctl start nginx
    systemctl enable nginx
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')

# Final health check
echo -e "${BLUE}🔍 Performing health check...${NC}"
sleep 2

if curl -f -s "http://localhost" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Application is responding correctly${NC}"
else
    echo -e "${YELLOW}⚠️  Health check failed, but files are deployed${NC}"
fi

# Display completion message
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📱 Your application is now available at:${NC}"
echo -e "   🌐 http://$SERVER_IP"
echo -e "   🌐 http://localhost (from server)"

echo -e "${BLUE}📋 Deployment summary:${NC}"
echo -e "   📁 Source: $(pwd)"
echo -e "   📁 Deployed to: $WEB_DIR"
echo -e "   💾 Backup location: $BACKUP_DIR"
echo -e "   📊 Files deployed: $(find $WEB_DIR -type f | wc -l) files"

echo -e "${BLUE}🔧 Useful commands:${NC}"
echo -e "   View deployed files: ${YELLOW}ls -la $WEB_DIR${NC}"
echo -e "   View backups: ${YELLOW}ls -la $BACKUP_DIR${NC}"
echo -e "   Check Nginx status: ${YELLOW}systemctl status nginx${NC}"
echo -e "   View Nginx logs: ${YELLOW}tail -f /var/log/nginx/error.log${NC}"
echo -e "   Redeploy: ${YELLOW}sudo ./upload-app.sh${NC}"

echo -e "${GREEN}✨ Ready to serve your Astro app!${NC}"