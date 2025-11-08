#!/bin/bash

################################################################################
# Quick Fix for Backend 404 Error
# This script updates the backend server.py to add root route
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Fixing Backend 404 Error${NC}"
echo ""

BACKEND_FILE="/var/www/html/macmapping/backend/server.py"

# Check if file exists
if [ ! -f "$BACKEND_FILE" ]; then
    echo -e "${RED}Error: $BACKEND_FILE not found!${NC}"
    exit 1
fi

echo "Backing up server.py..."
cp "$BACKEND_FILE" "$BACKEND_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✓ Backup created${NC}"
echo ""

# Check if root route already exists
if grep -q "@app.get(\"/\")" "$BACKEND_FILE"; then
    echo -e "${GREEN}✓ Root route already exists${NC}"
else
    echo "Adding root route to server.py..."
    
    # Find the line with "app.include_router" and add the root route before it
    sed -i '/# Include the router in the main app/i\
# Add a root route for the main app (without /api prefix)\
@app.get("/")\
async def root_redirect():\
    return {"message": "User-MAC Mapper API", "note": "Use /api/ endpoint", "version": "1.0"}\
\
' "$BACKEND_FILE"
    
    echo -e "${GREEN}✓ Root route added${NC}"
fi
echo ""

echo "Restarting backend..."
sudo supervisorctl restart macmapping-backend
sleep 2
echo -e "${GREEN}✓ Backend restarted${NC}"
echo ""

echo "Testing backend..."
echo ""

echo "Test 1: Root endpoint /"
curl -s http://localhost:8001/
echo ""
echo ""

echo "Test 2: API endpoint /api/"
curl -s http://localhost:8001/api/
echo ""
echo ""

echo -e "${GREEN}Done!${NC}"
echo ""
echo "If you see JSON responses above, the backend is working correctly."
