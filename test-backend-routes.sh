#!/bin/bash

echo "Testing Backend API Routes"
echo "=========================="
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
BACKEND_PORT=8001

echo "Server IP: $SERVER_IP"
echo "Backend Port: $BACKEND_PORT"
echo ""

echo "Test 1: Root endpoint (no /api prefix)"
echo "URL: http://localhost:$BACKEND_PORT/"
curl -s http://localhost:$BACKEND_PORT/ || echo "Failed"
echo ""
echo ""

echo "Test 2: /api endpoint"
echo "URL: http://localhost:$BACKEND_PORT/api"
curl -s http://localhost:$BACKEND_PORT/api
echo ""
echo ""

echo "Test 3: /api/ endpoint (with trailing slash)"
echo "URL: http://localhost:$BACKEND_PORT/api/"
curl -s http://localhost:$BACKEND_PORT/api/
echo ""
echo ""

echo "Test 4: /docs endpoint (FastAPI docs)"
echo "URL: http://localhost:$BACKEND_PORT/docs"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:$BACKEND_PORT/docs
echo ""

echo "Test 5: From external IP"
echo "URL: http://$SERVER_IP:$BACKEND_PORT/api/"
curl -s http://$SERVER_IP:$BACKEND_PORT/api/
echo ""
echo ""

echo "=========================="
echo "Frontend Configuration Check"
echo "=========================="
echo ""

if [ -f /var/www/html/macmapping/frontend/.env ]; then
    echo "Frontend .env file:"
    cat /var/www/html/macmapping/frontend/.env | grep REACT_APP_BACKEND_URL
else
    echo "Frontend .env file not found!"
fi
echo ""

echo "=========================="
echo "If all tests show 'Not Found', the backend routes may not be working correctly."
echo "Expected response: {\"message\":\"User-MAC Mapper API\",\"version\":\"1.0\"}"
