#!/bin/bash

################################################################################
# User-MAC Mapper Installation Script for Ubuntu 24.04
# This script installs all dependencies and sets up the application
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/var/www/html/macmapping"
REPO_URL="https://github.com/asherpoirier/macmapping.git"
BACKEND_PORT=8001
FRONTEND_PORT=3000

# Function to print colored messages
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Detect the actual user (not root)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
else
    # If not using sudo, ask for username
    print_warning "Running as root without sudo."
    read -p "Enter the username that should own the application (press Enter for 'www-data'): " ACTUAL_USER
    ACTUAL_USER=${ACTUAL_USER:-www-data}
fi

print_message "Starting User-MAC Mapper installation on Ubuntu 24.04..."
print_message "Application will run as user: $ACTUAL_USER"
echo ""

################################################################################
# 1. Update System
################################################################################
print_message "Step 1: Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"
echo ""

################################################################################
# 2. Install System Dependencies
################################################################################
print_message "Step 2: Installing system dependencies..."
apt install -y \
    git \
    curl \
    wget \
    build-essential \
    software-properties-common \
    nginx \
    supervisor \
    net-tools
print_success "System dependencies installed"
echo ""

################################################################################
# 3. Install Python 3.11+
################################################################################
print_message "Step 3: Installing Python 3.11+..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+')
print_success "Python $PYTHON_VERSION installed"
echo ""

################################################################################
# 4. Install Node.js and Yarn
################################################################################
print_message "Step 4: Installing Node.js 20.x and Yarn..."

# Remove old Node.js if exists
apt remove -y nodejs npm 2>/dev/null || true

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt update
apt install -y yarn

NODE_VERSION=$(node --version)
YARN_VERSION=$(yarn --version)
print_success "Node.js $NODE_VERSION installed"
print_success "Yarn $YARN_VERSION installed"
echo ""

################################################################################
# 5. Install MongoDB (Optional - if you plan to use it)
################################################################################
print_message "Step 5: Installing MongoDB..."
print_warning "MongoDB installation is optional. Current app doesn't use MongoDB for core functionality."
read -p "Do you want to install MongoDB? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    apt update
    apt install -y mongodb-org
    systemctl start mongod
    systemctl enable mongod
    print_success "MongoDB installed and started"
else
    print_warning "Skipping MongoDB installation"
fi
echo ""

################################################################################
# 6. Create Application Directory
################################################################################
print_message "Step 6: Creating application directory..."
mkdir -p $APP_DIR
print_success "Directory created: $APP_DIR"
echo ""

################################################################################
# 7. Clone Repository
################################################################################
print_message "Step 7: Cloning repository from GitHub..."
if [ -d "$APP_DIR/.git" ]; then
    print_warning "Repository already exists. Pulling latest changes..."
    cd $APP_DIR
    git pull origin main
else
    git clone $REPO_URL $APP_DIR
fi
cd $APP_DIR
print_success "Repository cloned"
echo ""

################################################################################
# 8. Setup Backend (Python/FastAPI)
################################################################################
print_message "Step 8: Setting up backend..."

cd $APP_DIR/backend

# Create virtual environment
print_message "Creating Python virtual environment..."
python3 -m venv venv
print_success "Virtual environment created"

# Activate virtual environment and install dependencies
print_message "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
print_success "Python dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_message "Creating backend .env file..."
    cat > .env << EOF
MONGO_URL="mongodb://localhost:27017"
DB_NAME="macmapping_db"
CORS_ORIGINS="*"
EOF
    print_success "Backend .env file created"
fi

echo ""

################################################################################
# 9. Setup Frontend (React)
################################################################################
print_message "Step 9: Setting up frontend..."

cd $APP_DIR/frontend

# Install frontend dependencies
print_message "Installing Node.js dependencies (this may take a few minutes)..."
yarn install
print_success "Node.js dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_message "Creating frontend .env file..."
    cat > .env << EOF
REACT_APP_BACKEND_URL=http://localhost:$BACKEND_PORT
PORT=$FRONTEND_PORT
REACT_APP_ENABLE_VISUAL_EDITS=false
ENABLE_HEALTH_CHECK=false
EOF
    print_success "Frontend .env file created"
fi

echo ""

################################################################################
# 10. Setup Supervisor for Process Management
################################################################################
print_message "Step 10: Setting up Supervisor for process management..."

# Backend supervisor config
cat > /etc/supervisor/conf.d/macmapping-backend.conf << EOF
[program:macmapping-backend]
directory=$APP_DIR/backend
command=$APP_DIR/backend/venv/bin/uvicorn server:app --host 0.0.0.0 --port $BACKEND_PORT --reload
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/macmapping-backend.err.log
stdout_logfile=/var/log/supervisor/macmapping-backend.out.log
user=$ACTUAL_USER
environment=PATH="$APP_DIR/backend/venv/bin"
EOF

# Frontend supervisor config
cat > /etc/supervisor/conf.d/macmapping-frontend.conf << EOF
[program:macmapping-frontend]
directory=$APP_DIR/frontend
command=yarn start
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/macmapping-frontend.err.log
stdout_logfile=/var/log/supervisor/macmapping-frontend.out.log
user=$ACTUAL_USER
environment=PATH="/usr/bin:/usr/local/bin"
EOF

# Reload supervisor
supervisorctl reread
supervisorctl update
print_success "Supervisor configured"
echo ""

################################################################################
# 11. Setup Nginx (Optional)
################################################################################
print_message "Step 11: Setting up Nginx reverse proxy..."
read -p "Do you want to configure Nginx as reverse proxy? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > /etc/nginx/sites-available/macmapping << 'EOF'
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/macmapping /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload nginx
    nginx -t && systemctl reload nginx
    print_success "Nginx configured and reloaded"
else
    print_warning "Skipping Nginx configuration"
fi
echo ""

################################################################################
# 12. Setup Firewall (Optional)
################################################################################
print_message "Step 12: Setting up firewall..."
read -p "Do you want to configure UFW firewall? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw --force enable
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow $BACKEND_PORT/tcp
    ufw allow $FRONTEND_PORT/tcp
    ufw status
    print_success "Firewall configured"
else
    print_warning "Skipping firewall configuration"
fi
echo ""

################################################################################
# 13. Start Services
################################################################################
print_message "Step 13: Starting services..."
supervisorctl start macmapping-backend
supervisorctl start macmapping-frontend
sleep 5
supervisorctl status
print_success "Services started"
echo ""

################################################################################
# 14. Create Helper Scripts
################################################################################
print_message "Step 14: Creating helper scripts..."

# Start script
cat > $APP_DIR/start.sh << EOF
#!/bin/bash
sudo supervisorctl start macmapping-backend macmapping-frontend
echo "Services started"
sudo supervisorctl status
EOF

# Stop script
cat > $APP_DIR/stop.sh << EOF
#!/bin/bash
sudo supervisorctl stop macmapping-backend macmapping-frontend
echo "Services stopped"
EOF

# Restart script
cat > $APP_DIR/restart.sh << EOF
#!/bin/bash
sudo supervisorctl restart macmapping-backend macmapping-frontend
echo "Services restarted"
sudo supervisorctl status
EOF

# Status script
cat > $APP_DIR/status.sh << EOF
#!/bin/bash
sudo supervisorctl status
EOF

# Logs script
cat > $APP_DIR/logs.sh << EOF
#!/bin/bash
echo "=== Backend Logs ==="
tail -n 50 /var/log/supervisor/macmapping-backend.err.log
echo ""
echo "=== Frontend Logs ==="
tail -n 50 /var/log/supervisor/macmapping-frontend.out.log
EOF

chmod +x $APP_DIR/*.sh
print_success "Helper scripts created"
echo ""

################################################################################
# Installation Complete
################################################################################

print_success "============================================="
print_success "Installation Complete!"
print_success "============================================="
echo ""

print_message "Application Details:"
echo "  📁 Installation Directory: $APP_DIR"
echo "  🔙 Backend URL: http://localhost:$BACKEND_PORT"
echo "  🎨 Frontend URL: http://localhost:$FRONTEND_PORT"
echo "  🌐 API Endpoint: http://localhost:$BACKEND_PORT/api"
echo ""

print_message "Service Management:"
echo "  Start:   sudo supervisorctl start macmapping-backend macmapping-frontend"
echo "  Stop:    sudo supervisorctl stop macmapping-backend macmapping-frontend"
echo "  Restart: sudo supervisorctl restart macmapping-backend macmapping-frontend"
echo "  Status:  sudo supervisorctl status"
echo ""
echo "  Or use helper scripts:"
echo "    $APP_DIR/start.sh"
echo "    $APP_DIR/stop.sh"
echo "    $APP_DIR/restart.sh"
echo "    $APP_DIR/status.sh"
echo "    $APP_DIR/logs.sh"
echo ""

print_message "Logs:"
echo "  Backend:  tail -f /var/log/supervisor/macmapping-backend.err.log"
echo "  Frontend: tail -f /var/log/supervisor/macmapping-frontend.out.log"
echo ""

print_message "Quick Test:"
echo "  curl http://localhost:$BACKEND_PORT/api/"
echo ""

print_warning "Important Notes:"
echo "  1. Frontend will take 2-3 minutes to compile on first run"
echo "  2. Backend should start immediately"
echo "  3. Check logs if services don't start: $APP_DIR/logs.sh"
echo "  4. Edit .env files in backend/ and frontend/ to customize settings"
echo ""

print_success "Ready to use! 🚀"
echo ""

# Test backend
print_message "Testing backend..."
sleep 3
if curl -s http://localhost:$BACKEND_PORT/api/ | grep -q "message"; then
    print_success "Backend is responding!"
else
    print_warning "Backend may still be starting. Check logs: tail -f /var/log/supervisor/macmapping-backend.err.log"
fi
