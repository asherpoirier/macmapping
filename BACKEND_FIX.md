# Backend 404 Error - Complete Fix Guide

## Problem
Frontend is getting 404 errors when trying to access backend API.

## Root Cause
The backend routes are under `/api` prefix, but something is calling the root `/` endpoint.

## Solutions

### Option 1: Quick Automated Fix (Recommended)

Run this on your Ubuntu server:

```bash
cd /var/www/html/macmapping

# Method A: Pull latest changes from GitHub
git pull origin main
sudo supervisorctl restart macmapping-backend

# Wait 2 seconds then test
sleep 2
curl http://localhost:8001/api/
```

### Option 2: Manual Fix

Edit the backend server.py file:

```bash
nano /var/www/html/macmapping/backend/server.py
```

Find this line (around line 176):
```python
# Include the router in the main app
app.include_router(api_router)
```

Add these lines **BEFORE** it:
```python
# Add a root route for the main app (without /api prefix)
@app.get("/")
async def root_redirect():
    return {"message": "User-MAC Mapper API", "note": "Use /api/ endpoint", "version": "1.0"}

```

Save the file (Ctrl+X, Y, Enter) and restart:
```bash
sudo supervisorctl restart macmapping-backend
```

### Option 3: Test Current Endpoints

The backend should work with these URLs regardless:

```bash
# This SHOULD work (returns API info)
curl http://192.168.1.210:8001/api/

# This might return 404 (but it's OK, not needed)
curl http://192.168.1.210:8001/
```

## Real Issue: Frontend Configuration

The main problem is likely that your frontend `.env` file has the wrong URL. 

### Check Frontend Config

```bash
cat /var/www/html/macmapping/frontend/.env
```

**It should show:**
```env
REACT_APP_BACKEND_URL=http://192.168.1.210:8001
```

**NOT:**
```env
REACT_APP_BACKEND_URL=http://localhost:8001
```

### Fix Frontend Config

```bash
# Edit the file
nano /var/www/html/macmapping/frontend/.env
```

**Make sure these lines exist:**
```env
REACT_APP_BACKEND_URL=http://192.168.1.210:8001
PORT=3000
REACT_APP_ENABLE_VISUAL_EDITS=false
ENABLE_HEALTH_CHECK=false
```

**Save and restart:**
```bash
sudo supervisorctl restart macmapping-frontend
```

**Wait 2-3 minutes** for the frontend to recompile, then refresh your browser.

## Verification Steps

### Step 1: Test Backend API

```bash
# From the server
curl http://localhost:8001/api/

# From your network
curl http://192.168.1.210:8001/api/
```

**Expected response:**
```json
{"message":"User-MAC Mapper API","version":"1.0"}
```

### Step 2: Check What Frontend Is Configured For

```bash
grep REACT_APP_BACKEND_URL /var/www/html/macmapping/frontend/.env
```

**Should output:**
```
REACT_APP_BACKEND_URL=http://192.168.1.210:8001
```

### Step 3: Check Browser

1. Open browser in **Incognito/Private mode**
2. Go to: `http://192.168.1.210:3000`
3. Press F12 to open Developer Tools
4. Go to Console tab
5. Upload files and click buttons
6. Check what URL is being called

**Should see:**
```
GET http://192.168.1.210:8001/api/preview
```

**NOT:**
```
GET http://localhost:8001/api/preview
```

## Common Issues

### Issue 1: Browser is Caching Old Configuration

**Fix:**
- Clear browser cache
- Or use Incognito/Private mode
- Or hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

### Issue 2: Frontend Not Recompiling

**Check if frontend is still compiling:**
```bash
tail -f /var/log/supervisor/macmapping-frontend.out.log
```

**Look for:**
```
Compiled successfully!
```

### Issue 3: CORS Error

If you see CORS errors in browser console:

**Fix backend CORS:**
```bash
nano /var/www/html/macmapping/backend/.env
```

**Make sure it has:**
```env
CORS_ORIGINS="*"
```

**Restart:**
```bash
sudo supervisorctl restart macmapping-backend
```

## Complete Reset Procedure

If nothing works, do a complete reset:

```bash
cd /var/www/html/macmapping

# Pull latest code
git pull origin main

# Update backend dependencies
cd backend
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

# Update frontend dependencies
cd frontend
yarn install
cd ..

# Fix frontend .env
cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://192.168.1.210:8001
PORT=3000
REACT_APP_ENABLE_VISUAL_EDITS=false
ENABLE_HEALTH_CHECK=false
EOF

# Restart everything
sudo supervisorctl restart macmapping-backend macmapping-frontend

# Wait for compilation
echo "Waiting 3 minutes for frontend to compile..."
sleep 180

# Test
curl http://192.168.1.210:8001/api/
```

Then open browser in incognito mode and test.

## Still Not Working?

Run the comprehensive troubleshooter:

```bash
cd /var/www/html/macmapping
bash troubleshoot-fetch-error.sh
```

And share the output.
