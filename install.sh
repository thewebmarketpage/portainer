#!/bin/bash

# Ensure the script runs inside the "portainer" directory
mkdir -p /var/www/html/portainer

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
fi

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable --now nginx
fi

# Run Portainer inside Docker
docker volume create portainer_data
docker run -d \
    -p 9000:9000 \
    --name portainer \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce

# Set up Nginx reverse proxy
echo "Configuring Nginx..."

sudo tee /etc/nginx/sites-available/portainer <<EOF
server {
    listen 80;
    server_name _;

    location /portainer/ {
        proxy_pass http://localhost:9000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        rewrite ^/portainer(/.*) \$1 break;
    }
}
EOF

# Enable Nginx config and restart
sudo ln -sf /etc/nginx/sites-available/portainer /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "Portainer is now available at http://your-server-ip/portainer/"
