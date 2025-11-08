#!/bin/bash

################################################################################
# Installation Test Script
# This script tests if the User-MAC Mapper installation was successful
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_DIR="/var/www/html/macmapping"
BACKEND_URL="http://localhost:8001"
FRONTEND_URL="http://localhost:3000"

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}User-MAC Mapper Installation Test${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

test_title() {
    echo ""
    echo -e "${BLUE}Testing:${NC} $1"
}

# Test 1: Check if directory exists
test_title "Application directory"
if [ -d "$APP_DIR" ]; then
    pass "Directory exists: $APP_DIR"
else
    fail "Directory not found: $APP_DIR"
fi

# Test 2: Check if Git repository
test_title "Git repository"
if [ -d "$APP_DIR/.git" ]; then
    pass "Git repository initialized"
else
    fail "Not a Git repository"
fi

# Test 3: Check Python
test_title "Python installation"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    pass "Python installed: $PYTHON_VERSION"
else
    fail "Python not found"
fi

# Test 4: Check Node.js
test_title "Node.js installation"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    pass "Node.js installed: $NODE_VERSION"
else
    fail "Node.js not found"
fi

# Test 5: Check Yarn
test_title "Yarn installation"
if command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn --version)
    pass "Yarn installed: $YARN_VERSION"
else
    fail "Yarn not found"
fi

# Test 6: Check backend virtual environment
test_title "Backend virtual environment"
if [ -d "$APP_DIR/backend/venv" ]; then
    pass "Virtual environment exists"
else
    fail "Virtual environment not found"
fi

# Test 7: Check backend .env
test_title "Backend configuration"
if [ -f "$APP_DIR/backend/.env" ]; then
    pass "Backend .env file exists"
else
    fail "Backend .env file not found"
fi

# Test 8: Check frontend node_modules
test_title "Frontend dependencies"
if [ -d "$APP_DIR/frontend/node_modules" ]; then
    pass "Frontend dependencies installed"
else
    warn "Frontend dependencies not installed (may still be installing)"
fi

# Test 9: Check frontend .env
test_title "Frontend configuration"
if [ -f "$APP_DIR/frontend/.env" ]; then
    pass "Frontend .env file exists"
else
    fail "Frontend .env file not found"
fi

# Test 10: Check Supervisor
test_title "Supervisor installation"
if command -v supervisorctl &> /dev/null; then
    pass "Supervisor installed"
else
    fail "Supervisor not found"
fi

# Test 11: Check backend supervisor config
test_title "Backend supervisor config"
if [ -f "/etc/supervisor/conf.d/macmapping-backend.conf" ]; then
    pass "Backend supervisor config exists"
else
    fail "Backend supervisor config not found"
fi

# Test 12: Check frontend supervisor config
test_title "Frontend supervisor config"
if [ -f "/etc/supervisor/conf.d/macmapping-frontend.conf" ]; then
    pass "Frontend supervisor config exists"
else
    fail "Frontend supervisor config not found"
fi

# Test 13: Check if backend is running
test_title "Backend service"
if sudo supervisorctl status macmapping-backend | grep -q RUNNING; then
    pass "Backend service is running"
    
    # Test 14: Check backend API
    test_title "Backend API response"
    if curl -s "$BACKEND_URL/api/" | grep -q "message"; then
        pass "Backend API is responding"
    else
        fail "Backend API not responding"
    fi
else
    fail "Backend service not running"
    warn "Start with: sudo supervisorctl start macmapping-backend"
fi

# Test 15: Check if frontend is running
test_title "Frontend service"
if sudo supervisorctl status macmapping-frontend | grep -q RUNNING; then
    pass "Frontend service is running"
    
    # Test 16: Check frontend response
    test_title "Frontend response"
    if curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" | grep -q "200"; then
        pass "Frontend is responding"
    else
        warn "Frontend not responding yet (may still be compiling)"
    fi
else
    fail "Frontend service not running"
    warn "Start with: sudo supervisorctl start macmapping-frontend"
fi

# Test 17: Check Nginx
test_title "Nginx (optional)"
if command -v nginx &> /dev/null; then
    pass "Nginx installed"
    
    if [ -f "/etc/nginx/sites-available/macmapping" ]; then
        pass "Nginx configuration exists"
    else
        warn "Nginx configuration not found (optional)"
    fi
else
    warn "Nginx not installed (optional)"
fi

# Test 18: Check MongoDB
test_title "MongoDB (optional)"
if command -v mongod &> /dev/null; then
    pass "MongoDB installed"
    
    if systemctl is-active --quiet mongod; then
        pass "MongoDB is running"
    else
        warn "MongoDB installed but not running"
    fi
else
    warn "MongoDB not installed (optional)"
fi

# Test 19: Check helper scripts
test_title "Helper scripts"
HELPER_SCRIPTS=("start.sh" "stop.sh" "restart.sh" "status.sh" "logs.sh")
SCRIPTS_OK=0

for script in "${HELPER_SCRIPTS[@]}"; do
    if [ -x "$APP_DIR/$script" ]; then
        ((SCRIPTS_OK++))
    fi
done

if [ $SCRIPTS_OK -eq ${#HELPER_SCRIPTS[@]} ]; then
    pass "All helper scripts present and executable"
else
    warn "$SCRIPTS_OK/${#HELPER_SCRIPTS[@]} helper scripts found"
fi

# Test 20: Check ports
test_title "Port availability"
if sudo netstat -tulpn | grep -q ":8001"; then
    pass "Port 8001 is in use (backend)"
else
    warn "Port 8001 is not in use (backend may not be running)"
fi

if sudo netstat -tulpn | grep -q ":3000"; then
    pass "Port 3000 is in use (frontend)"
else
    warn "Port 3000 is not in use (frontend may not be running)"
fi

# Summary
echo ""
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""
echo -e "${GREEN}Tests Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Tests Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Access the application:"
    echo "  Frontend: $FRONTEND_URL"
    echo "  Backend:  $BACKEND_URL/api/"
    echo ""
    echo "Service management:"
    echo "  cd $APP_DIR"
    echo "  ./start.sh   - Start services"
    echo "  ./stop.sh    - Stop services"
    echo "  ./restart.sh - Restart services"
    echo "  ./status.sh  - Check status"
    echo "  ./logs.sh    - View logs"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Installation has issues${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check logs: tail -f /var/log/supervisor/macmapping-*.log"
    echo "  2. Check status: sudo supervisorctl status"
    echo "  3. Restart services: sudo supervisorctl restart macmapping-backend macmapping-frontend"
    echo "  4. Review installation guide: $APP_DIR/INSTALL_UBUNTU.md"
    echo ""
    exit 1
fi
