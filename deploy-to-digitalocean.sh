#!/bin/bash

# Digital Ocean Deployment Script for Astro App
# This script deploys the one-remit-merchant app to a Digital Ocean droplet

set -e  # Exit on any error

# Configuration - UPDATE THESE VALUES
DROPLET_IP="YOUR_DROPLET_IP"           # Replace with your droplet IP
DROPLET_USER="root"                    # Or your preferred user
SSH_KEY_PATH="~/.ssh/id_rsa"          # Path to your SSH private key
APP_NAME="one-remit-merchant"
DOMAIN_NAME="your-domain.com"          # Optional: your domain name
PORT="3000"                           # Port for the app

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting deployment to Digital Ocean droplet...${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if required variables are set
if [ "$DROPLET_IP" = "YOUR_DROPLET_IP" ]; then
    print_error "Please update DROPLET_IP in the script with your actual droplet IP"
    exit 1
fi

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    print_error "SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

# Test SSH connection
echo -e "${BLUE}🔐 Testing SSH connection...${NC}"
if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$DROPLET_USER@$DROPLET_IP" "echo 'SSH connection successful'" > /dev/null 2>&1; then
    print_status "SSH connection successful"
else
    print_error "Cannot connect to droplet via SSH. Please check your IP, SSH key, and droplet status."
    exit 1
fi

# Build the Astro app locally
echo -e "${BLUE}🏗️  Building Astro app locally...${NC}"
if command -v npm &> /dev/null; then
    npm install
    npm run build
    print_status "Astro app built successfully"
else
    print_error "npm not found. Please install Node.js and npm"
    exit 1
fi

# Create deployment directory on droplet
echo -e "${BLUE}📁 Setting up directories on droplet...${NC}"
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << 'EOF'
    # Update system
    apt update && apt upgrade -y
    
    # Install Node.js and npm if not present
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        apt-get install -y nodejs
    fi
    
    # Install PM2 for process management
    if ! command -v pm2 &> /dev/null; then
        npm install -g pm2
    fi
    
    # Install Nginx if not present
    if ! command -v nginx &> /dev/null; then
        apt install -y nginx
    fi
    
    # Create app directory
    mkdir -p /var/www/one-remit-merchant
    
    # Create backup of current deployment if exists
    if [ -d "/var/www/one-remit-merchant/current" ]; then
        mv /var/www/one-remit-merchant/current /var/www/one-remit-merchant/backup-$(date +%Y%m%d-%H%M%S)
    fi
    
    mkdir -p /var/www/one-remit-merchant/current
EOF

print_status "Droplet setup completed"

# Upload built files to droplet
echo -e "${BLUE}📤 Uploading files to droplet...${NC}"
scp -i "$SSH_KEY_PATH" -r dist/* "$DROPLET_USER@$DROPLET_IP:/var/www/$APP_NAME/current/"
scp -i "$SSH_KEY_PATH" package.json "$DROPLET_USER@$DROPLET_IP:/var/www/$APP_NAME/current/"
scp -i "$SSH_KEY_PATH" package-lock.json "$DROPLET_USER@$DROPLET_IP:/var/www/$APP_NAME/current/" 2>/dev/null || true

print_status "Files uploaded successfully"

# Create server.js for serving the static files
echo -e "${BLUE}🖥️  Creating server configuration...${NC}"
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << EOF
cat > /var/www/$APP_NAME/current/server.js << 'SERVERJS'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || $PORT;

// Serve static files from the current directory
app.use(express.static('.'));

// Handle client-side routing (SPA)
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
    console.log(\`🚀 Server running on port \${PORT}\`);
    console.log(\`🌐 Access your app at http://localhost:\${PORT}\`);
});
SERVERJS

# Install express
cd /var/www/$APP_NAME/current
npm init -y
npm install express

# Create PM2 ecosystem file
cat > ecosystem.config.js << 'ECOJS'
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: $PORT
    }
  }]
};
ECOJS
EOF

print_status "Server configuration created"

# Configure Nginx
echo -e "${BLUE}🌐 Configuring Nginx...${NC}"
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << EOF
# Create Nginx configuration
cat > /etc/nginx/sites-available/$APP_NAME << 'NGINXCONF'
server {
    listen 80;
    server_name $DROPLET_IP $DOMAIN_NAME;
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXCONF

# Enable the site
ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx
EOF

print_status "Nginx configured successfully"

# Start the application with PM2
echo -e "${BLUE}🚀 Starting application with PM2...${NC}"
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << EOF
cd /var/www/$APP_NAME/current

# Stop existing PM2 process if running
pm2 stop $APP_NAME 2>/dev/null || true
pm2 delete $APP_NAME 2>/dev/null || true

# Start the application
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Show PM2 status
pm2 status
EOF

print_status "Application started successfully"

# Configure firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
ssh -i "$SSH_KEY_PATH" "$DROPLET_USER@$DROPLET_IP" << 'EOF'
# Configure UFW firewall
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 3000
ufw status
EOF

print_status "Firewall configured"

# Final status check
echo -e "${BLUE}🔍 Performing final health check...${NC}"
sleep 5

if curl -f -s "http://$DROPLET_IP" > /dev/null; then
    print_status "Application is running successfully!"
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${BLUE}📱 Your app is now available at:${NC}"
    echo -e "   🌐 http://$DROPLET_IP"
    if [ "$DOMAIN_NAME" != "your-domain.com" ]; then
        echo -e "   🌐 http://$DOMAIN_NAME"
    fi
else
    print_warning "Application might still be starting up. Please check manually."
fi

echo -e "${BLUE}📋 Useful commands for managing your app:${NC}"
echo -e "   SSH into droplet: ${YELLOW}ssh -i $SSH_KEY_PATH $DROPLET_USER@$DROPLET_IP${NC}"
echo -e "   View PM2 status: ${YELLOW}pm2 status${NC}"
echo -e "   View app logs: ${YELLOW}pm2 logs $APP_NAME${NC}"
echo -e "   Restart app: ${YELLOW}pm2 restart $APP_NAME${NC}"
echo -e "   View Nginx logs: ${YELLOW}tail -f /var/log/nginx/error.log${NC}"

echo -e "${GREEN}✨ Deployment script completed!${NC}"