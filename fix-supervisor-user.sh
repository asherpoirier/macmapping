#!/bin/bash

################################################################################
# Fix Supervisor User Configuration
# Run this if you got "Invalid user name" error during installation
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

APP_DIR="/var/www/html/macmapping"
BACKEND_PORT=8001
FRONTEND_PORT=3000

print_message "Fixing Supervisor configuration..."
echo ""

# Detect user
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
else
    print_message "Available users:"
    grep -E ":/home|:/root" /etc/passwd | cut -d: -f1 | nl
    echo ""
    read -p "Enter username to run the application (or press Enter for 'www-data'): " ACTUAL_USER
    ACTUAL_USER=${ACTUAL_USER:-www-data}
fi

# Verify user exists
if ! id "$ACTUAL_USER" &>/dev/null; then
    print_error "User '$ACTUAL_USER' does not exist!"
    
    # Offer to create www-data user if it doesn't exist
    if [ "$ACTUAL_USER" = "www-data" ]; then
        print_message "Creating www-data user..."
        useradd -r -s /usr/sbin/nologin www-data 2>/dev/null || true
        print_success "www-data user created"
    else
        exit 1
    fi
fi

print_message "Using user: $ACTUAL_USER"
echo ""

# Fix backend supervisor config
print_message "Fixing backend supervisor configuration..."
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
print_success "Backend config fixed"

# Fix frontend supervisor config
print_message "Fixing frontend supervisor configuration..."
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
print_success "Frontend config fixed"

# Fix permissions
print_message "Fixing file permissions..."
chown -R $ACTUAL_USER:$ACTUAL_USER $APP_DIR
print_success "Permissions fixed"

# Reload supervisor
print_message "Reloading supervisor..."
supervisorctl reread
supervisorctl update
print_success "Supervisor reloaded"

# Start services
print_message "Starting services..."
supervisorctl start macmapping-backend macmapping-frontend
sleep 3

# Check status
print_message "Service status:"
supervisorctl status macmapping-backend macmapping-frontend

echo ""
print_success "Configuration fixed!"
echo ""

print_message "Checking if services are running..."
if supervisorctl status macmapping-backend | grep -q RUNNING; then
    print_success "Backend is running"
else
    print_error "Backend failed to start. Check logs:"
    echo "  tail -f /var/log/supervisor/macmapping-backend.err.log"
fi

if supervisorctl status macmapping-frontend | grep -q RUNNING; then
    print_success "Frontend is running"
else
    print_error "Frontend failed to start. Check logs:"
    echo "  tail -f /var/log/supervisor/macmapping-frontend.out.log"
fi

echo ""
print_message "Test the application:"
echo "  Backend:  curl http://localhost:$BACKEND_PORT/api/"
echo "  Frontend: http://localhost:$FRONTEND_PORT"
echo ""
