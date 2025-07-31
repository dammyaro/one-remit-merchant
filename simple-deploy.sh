#!/bin/bash

# Simple Digital Ocean Deployment Script
# Quick deployment for Astro static site

set -e

# Configuration - UPDATE THESE
DROPLET_IP="YOUR_DROPLET_IP"
DROPLET_USER="root"
SSH_KEY_PATH="~/.ssh/id_rsa"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Simple deployment to Digital Ocean...${NC}"

# Validate configuration
if [ "$DROPLET_IP" = "YOUR_DROPLET_IP" ]; then
    echo -e "${RED}❌ Please update DROPLET_IP in the script${NC}"
    exit 1
fi

# Build locally
echo -e "${BLUE}🏗️  Building app...${NC}"
npm install
npm run build

# Deploy to droplet
echo -e "${BLUE}📤 Deploying to droplet...${NC}"
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << 'EOF'
    # Install nginx if not present
    apt update
    apt install -y nginx
    
    # Create web directory
    mkdir -p /var/www/html
    
    # Backup existing files
    mv /var/www/html /var/www/html.backup.$(date +%s) 2>/dev/null || true
    mkdir -p /var/www/html
EOF

# Upload files
echo -e "${BLUE}📁 Uploading files...${NC}"
scp -i "$SSH_KEY_PATH" -r dist/* "$DROPLET_USER@$DROPLET_IP:/var/www/html/"

# Configure nginx
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << 'EOF'
    # Simple nginx config
    cat > /etc/nginx/sites-available/default << 'NGINXCONF'
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
NGINXCONF

    # Restart nginx
    nginx -t
    systemctl restart nginx
    systemctl enable nginx
    
    # Configure firewall
    ufw --force enable
    ufw allow ssh
    ufw allow 80
    ufw allow 443
EOF

echo -e "${GREEN}✅ Deployment completed!${NC}"
echo -e "${BLUE}🌐 Your app is available at: http://$DROPLET_IP${NC}"