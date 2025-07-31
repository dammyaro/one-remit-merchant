#!/bin/bash

# Upload application files to server
# Run this script on your LOCAL machine to upload files to the server

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

echo -e "${BLUE}📤 Uploading app files to server...${NC}"

# Validate configuration
if [ "$DROPLET_IP" = "YOUR_DROPLET_IP" ]; then
    echo -e "${RED}❌ Please update DROPLET_IP in the script${NC}"
    exit 1
fi

# Build the app locally
echo -e "${BLUE}🏗️  Building app locally...${NC}"
npm install
npm run build

# Create deployment package
echo -e "${BLUE}📦 Creating deployment package...${NC}"
cd dist
tar -czf ../app-deployment.tar.gz *
cd ..

# Upload to server
echo -e "${BLUE}📤 Uploading to server...${NC}"
scp -i "$SSH_KEY_PATH" app-deployment.tar.gz "$DROPLET_USER@$DROPLET_IP:/tmp/"

# Extract on server and deploy
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << 'EOF'
    cd /tmp
    
    # Backup existing files
    if [ -d "/var/www/html" ] && [ "$(ls -A /var/www/html)" ]; then
        mkdir -p /var/backups/web
        tar -czf "/var/backups/web/backup-$(date +%Y%m%d-%H%M%S).tar.gz" -C /var/www/html .
        echo "✅ Backup created"
    fi
    
    # Clear web directory and extract new files
    rm -rf /var/www/html/*
    tar -xzf app-deployment.tar.gz -C /var/www/html/
    
    # Set permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Reload nginx
    systemctl reload nginx
    
    # Cleanup
    rm -f /tmp/app-deployment.tar.gz
    
    echo "✅ Deployment completed"
EOF

# Cleanup local files
rm -f app-deployment.tar.gz

echo -e "${GREEN}🎉 Upload completed!${NC}"
echo -e "${BLUE}🌐 Your app should now be live at: http://$DROPLET_IP${NC}"