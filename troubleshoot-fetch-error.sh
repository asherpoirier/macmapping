#!/bin/bash

################################################################################
# Troubleshoot "Failed to Fetch" Error
# This script diagnoses why the frontend cannot connect to the backend
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=======================================${NC}"
}

print_step() {
    echo -e "\n${BLUE}Step $1: $2${NC}"
}

print_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header "Frontend-Backend Connection Troubleshooter"

# Variables
BACKEND_PORT=8001
FRONTEND_PORT=3000
APP_DIR="/var/www/html/macmapping"

# Step 1: Check if services are running
print_step "1" "Checking if services are running"

if command -v supervisorctl &> /dev/null; then
    echo "Supervisor status:"
    sudo supervisorctl status | grep macmapping
    
    BACKEND_RUNNING=$(sudo supervisorctl status macmapping-backend | grep -c RUNNING)
    FRONTEND_RUNNING=$(sudo supervisorctl status macmapping-frontend | grep -c RUNNING)
    
    if [ $BACKEND_RUNNING -eq 1 ]; then
        print_pass "Backend service is RUNNING"
    else
        print_fail "Backend service is NOT running"
        echo "  Fix: sudo supervisorctl start macmapping-backend"
    fi
    
    if [ $FRONTEND_RUNNING -eq 1 ]; then
        print_pass "Frontend service is RUNNING"
    else
        print_fail "Frontend service is NOT running"
        echo "  Fix: sudo supervisorctl start macmapping-frontend"
    fi
else
    print_warn "Supervisor not found. Cannot check service status."
fi

# Step 2: Check if ports are listening
print_step "2" "Checking if ports are listening"

if sudo netstat -tulpn | grep -q ":$BACKEND_PORT "; then
    print_pass "Port $BACKEND_PORT is listening (backend)"
    BACKEND_PID=$(sudo netstat -tulpn | grep ":$BACKEND_PORT " | awk '{print $7}' | cut -d'/' -f1)
    echo "  PID: $BACKEND_PID"
else
    print_fail "Port $BACKEND_PORT is NOT listening (backend)"
fi

if sudo netstat -tulpn | grep -q ":$FRONTEND_PORT "; then
    print_pass "Port $FRONTEND_PORT is listening (frontend)"
    FRONTEND_PID=$(sudo netstat -tulpn | grep ":$FRONTEND_PORT " | awk '{print $7}' | cut -d'/' -f1)
    echo "  PID: $FRONTEND_PID"
else
    print_fail "Port $FRONTEND_PORT is NOT listening (frontend)"
fi

# Step 3: Test backend API directly
print_step "3" "Testing backend API directly"

echo "Testing: http://localhost:$BACKEND_PORT/api/"
BACKEND_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:$BACKEND_PORT/api/ 2>&1)
BACKEND_CODE=$(echo "$BACKEND_RESPONSE" | tail -n 1)
BACKEND_BODY=$(echo "$BACKEND_RESPONSE" | sed '$d')

if [ "$BACKEND_CODE" = "200" ]; then
    print_pass "Backend API is responding (HTTP $BACKEND_CODE)"
    echo "  Response: $BACKEND_BODY"
else
    print_fail "Backend API is NOT responding properly (HTTP $BACKEND_CODE)"
    echo "  Response: $BACKEND_RESPONSE"
fi

# Step 4: Check backend .env configuration
print_step "4" "Checking backend configuration"

if [ -f "$APP_DIR/backend/.env" ]; then
    print_pass "Backend .env file exists"
    echo ""
    echo "Backend .env contents:"
    cat "$APP_DIR/backend/.env"
else
    print_fail "Backend .env file NOT found"
fi

# Step 5: Check frontend .env configuration
print_step "5" "Checking frontend configuration"

if [ -f "$APP_DIR/frontend/.env" ]; then
    print_pass "Frontend .env file exists"
    echo ""
    echo "Frontend .env contents:"
    cat "$APP_DIR/frontend/.env"
    
    # Check REACT_APP_BACKEND_URL
    BACKEND_URL=$(grep REACT_APP_BACKEND_URL "$APP_DIR/frontend/.env" | cut -d'=' -f2 | tr -d '"')
    echo ""
    echo "Frontend is configured to use backend at: $BACKEND_URL"
    
    # Check if it matches localhost
    if echo "$BACKEND_URL" | grep -q "localhost"; then
        print_pass "Frontend is configured for localhost"
    else
        print_warn "Frontend is NOT configured for localhost: $BACKEND_URL"
        echo "  Your IP appears to be: $(hostname -I | awk '{print $1}')"
        echo "  Frontend might be trying to reach: $BACKEND_URL"
    fi
else
    print_fail "Frontend .env file NOT found"
fi

# Step 6: Check backend logs
print_step "6" "Checking backend logs (last 20 lines)"

if [ -f "/var/log/supervisor/macmapping-backend.err.log" ]; then
    echo ""
    tail -n 20 /var/log/supervisor/macmapping-backend.err.log
else
    print_warn "Backend log file not found"
fi

# Step 7: Check frontend logs
print_step "7" "Checking frontend logs (last 20 lines)"

if [ -f "/var/log/supervisor/macmapping-frontend.out.log" ]; then
    echo ""
    tail -n 20 /var/log/supervisor/macmapping-frontend.out.log | grep -E "(Compiled|Failed|error|Error)" || echo "No obvious errors in frontend logs"
else
    print_warn "Frontend log file not found"
fi

# Step 8: Check CORS configuration
print_step "8" "Checking CORS configuration"

if [ -f "$APP_DIR/backend/.env" ]; then
    CORS_ORIGINS=$(grep CORS_ORIGINS "$APP_DIR/backend/.env" | cut -d'=' -f2 | tr -d '"')
    echo "CORS_ORIGINS: $CORS_ORIGINS"
    
    if [ "$CORS_ORIGINS" = "*" ]; then
        print_pass "CORS is set to allow all origins (*)"
    else
        print_warn "CORS is restricted to: $CORS_ORIGINS"
        echo "  This might block requests if frontend URL doesn't match"
    fi
fi

# Step 9: Test from the client's perspective
print_step "9" "Testing backend from client IP perspective"

SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"
echo ""
echo "Testing: http://$SERVER_IP:$BACKEND_PORT/api/"

REMOTE_RESPONSE=$(curl -s -w "\n%{http_code}" http://$SERVER_IP:$BACKEND_PORT/api/ 2>&1)
REMOTE_CODE=$(echo "$REMOTE_RESPONSE" | tail -n 1)

if [ "$REMOTE_CODE" = "200" ]; then
    print_pass "Backend is accessible from server IP"
else
    print_fail "Backend is NOT accessible from server IP (HTTP $REMOTE_CODE)"
    echo "  This might be a firewall issue"
fi

# Summary and Recommendations
print_header "Summary and Recommendations"

echo ""
echo "Common fixes for 'Failed to fetch' error:"
echo ""
echo "1. If backend is not running:"
echo "   sudo supervisorctl start macmapping-backend"
echo ""
echo "2. If backend is running but not responding:"
echo "   sudo supervisorctl restart macmapping-backend"
echo "   tail -f /var/log/supervisor/macmapping-backend.err.log"
echo ""
echo "3. If frontend REACT_APP_BACKEND_URL is wrong:"
echo "   Edit: $APP_DIR/frontend/.env"
echo "   Change REACT_APP_BACKEND_URL to: http://$SERVER_IP:$BACKEND_PORT"
echo "   Then: sudo supervisorctl restart macmapping-frontend"
echo ""
echo "4. If firewall is blocking:"
echo "   sudo ufw allow $BACKEND_PORT/tcp"
echo "   sudo ufw allow $FRONTEND_PORT/tcp"
echo ""
echo "5. Check if backend dependencies are installed:"
echo "   cd $APP_DIR/backend"
echo "   source venv/bin/activate"
echo "   pip install -r requirements.txt"
echo ""
echo "Access URLs:"
echo "  From server:  http://localhost:$FRONTEND_PORT"
echo "  From network: http://$SERVER_IP:$FRONTEND_PORT"
echo ""
