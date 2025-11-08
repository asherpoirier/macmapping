# Installation Guide for Ubuntu 24.04

This guide provides instructions for installing the User-MAC Mapper application on Ubuntu 24.04.

## Quick Install (Automated)

### One-Line Installation

```bash
sudo apt update && sudo apt install -y git && \
git clone https://github.com/asherpoirier/macmapping.git /tmp/macmapping && \
sudo bash /tmp/macmapping/install-ubuntu.sh
```

### Step-by-Step Installation

1. **Download the repository**
   ```bash
   git clone https://github.com/asherpoirier/macmapping.git
   cd macmapping
   ```

2. **Run the installation script**
   ```bash
   sudo bash install-ubuntu.sh
   ```

3. **Follow the prompts**
   - MongoDB installation (optional - not required for core functionality)
   - Nginx reverse proxy setup (recommended)
   - UFW firewall configuration (optional)

4. **Wait for installation to complete** (5-10 minutes)

## What Gets Installed

### System Packages
- **Git**: Version control
- **curl, wget**: Download tools
- **build-essential**: Compiler tools
- **nginx**: Web server (optional)
- **supervisor**: Process manager

### Programming Languages & Runtimes
- **Python 3.11+**: Backend runtime
- **pip**: Python package manager
- **Node.js 20.x**: Frontend runtime
- **Yarn**: Node.js package manager

### Optional Components
- **MongoDB 7.0**: Database (optional)
- **UFW**: Firewall (optional)

## Directory Structure

After installation:

```
/var/www/html/macmapping/
├── backend/
│   ├── venv/              # Python virtual environment
│   ├── server.py          # FastAPI application
│   ├── requirements.txt   # Python dependencies
│   └── .env              # Backend configuration
├── frontend/
│   ├── node_modules/     # Node.js dependencies
│   ├── src/              # React source code
│   ├── public/           # Static assets
│   ├── package.json      # Node.js dependencies
│   └── .env             # Frontend configuration
├── user_mac_mapper.py    # Standalone CLI script
├── start.sh             # Start services
├── stop.sh              # Stop services
├── restart.sh           # Restart services
├── status.sh            # Check service status
└── logs.sh              # View logs
```

## Service Management

### Using Helper Scripts

```bash
cd /var/www/html/macmapping

# Start services
./start.sh

# Stop services
./stop.sh

# Restart services
./restart.sh

# Check status
./status.sh

# View logs
./logs.sh
```

### Using Supervisor Directly

```bash
# Start services
sudo supervisorctl start macmapping-backend macmapping-frontend

# Stop services
sudo supervisorctl stop macmapping-backend macmapping-frontend

# Restart services
sudo supervisorctl restart macmapping-backend macmapping-frontend

# Check status
sudo supervisorctl status

# View all processes
sudo supervisorctl
```

### Using Systemctl (Supervisor itself)

```bash
# Start supervisor
sudo systemctl start supervisor

# Stop supervisor
sudo systemctl stop supervisor

# Restart supervisor
sudo systemctl restart supervisor

# Enable on boot
sudo systemctl enable supervisor
```

## Configuration

### Backend Configuration

Edit `/var/www/html/macmapping/backend/.env`:

```env
MONGO_URL="mongodb://localhost:27017"
DB_NAME="macmapping_db"
CORS_ORIGINS="*"
```

After changes, restart backend:
```bash
sudo supervisorctl restart macmapping-backend
```

### Frontend Configuration

Edit `/var/www/html/macmapping/frontend/.env`:

```env
REACT_APP_BACKEND_URL=http://localhost:8001
PORT=3000
REACT_APP_ENABLE_VISUAL_EDITS=false
ENABLE_HEALTH_CHECK=false
```

After changes, restart frontend:
```bash
sudo supervisorctl restart macmapping-frontend
```

### Nginx Configuration (if installed)

Edit `/etc/nginx/sites-available/macmapping`

After changes:
```bash
sudo nginx -t                    # Test configuration
sudo systemctl reload nginx      # Apply changes
```

## Accessing the Application

### Local Access

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001/api/
- **API Health Check**: http://localhost:8001/api/

### Remote Access (if Nginx configured)

- **Frontend**: http://your-server-ip/
- **Backend API**: http://your-server-ip/api/

## Troubleshooting

### Check Service Status

```bash
sudo supervisorctl status
```

Expected output:
```
macmapping-backend           RUNNING   pid 1234, uptime 0:05:23
macmapping-frontend          RUNNING   pid 1235, uptime 0:05:23
```

### View Logs

**Backend logs:**
```bash
tail -f /var/log/supervisor/macmapping-backend.err.log
```

**Frontend logs:**
```bash
tail -f /var/log/supervisor/macmapping-frontend.out.log
```

**All logs:**
```bash
./logs.sh
```

### Common Issues

#### 1. Backend not starting

**Check logs:**
```bash
tail -50 /var/log/supervisor/macmapping-backend.err.log
```

**Common fixes:**
- Check Python dependencies: `cd /var/www/html/macmapping/backend && source venv/bin/activate && pip install -r requirements.txt`
- Check .env file exists
- Check port 8001 is not in use: `sudo netstat -tulpn | grep 8001`

#### 2. Frontend not starting

**Check logs:**
```bash
tail -50 /var/log/supervisor/macmapping-frontend.out.log
```

**Common fixes:**
- Wait 2-3 minutes for initial compilation
- Check Node.js dependencies: `cd /var/www/html/macmapping/frontend && yarn install`
- Check .env file exists
- Check port 3000 is not in use: `sudo netstat -tulpn | grep 3000`

#### 3. Port already in use

**Find what's using the port:**
```bash
sudo lsof -i :8001  # Backend
sudo lsof -i :3000  # Frontend
```

**Kill the process:**
```bash
sudo kill -9 <PID>
```

#### 4. Permission errors

**Fix permissions:**
```bash
sudo chown -R $USER:$USER /var/www/html/macmapping
```

#### 5. Nginx 502 Bad Gateway

- Check if backend is running: `curl http://localhost:8001/api/`
- Check if frontend is running: `curl http://localhost:3000`
- Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`

## Testing the Installation

### 1. Test Backend API

```bash
curl http://localhost:8001/api/
```

Expected response:
```json
{"message":"User-MAC Mapper API","version":"1.0"}
```

### 2. Test Frontend

Open browser: http://localhost:3000

You should see the User-MAC Address Mapper interface.

### 3. Test Full Flow

1. Open http://localhost:3000
2. Upload 3 CSV files (old users, MACs, new users)
3. Click "Preview Mapping"
4. Click "Generate & Download CSV"
5. Check that CSV opens in new tab with download options

## Updating the Application

### Pull Latest Changes

```bash
cd /var/www/html/macmapping
git pull origin main
```

### Update Backend Dependencies

```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
deactivate
sudo supervisorctl restart macmapping-backend
```

### Update Frontend Dependencies

```bash
cd frontend
yarn install
sudo supervisorctl restart macmapping-frontend
```

## Uninstalling

### 1. Stop Services

```bash
sudo supervisorctl stop macmapping-backend macmapping-frontend
```

### 2. Remove Supervisor Configs

```bash
sudo rm /etc/supervisor/conf.d/macmapping-backend.conf
sudo rm /etc/supervisor/conf.d/macmapping-frontend.conf
sudo supervisorctl reread
sudo supervisorctl update
```

### 3. Remove Application Files

```bash
sudo rm -rf /var/www/html/macmapping
```

### 4. Remove Nginx Config (if installed)

```bash
sudo rm /etc/nginx/sites-available/macmapping
sudo rm /etc/nginx/sites-enabled/macmapping
sudo systemctl reload nginx
```

### 5. Optionally Remove Packages

```bash
# Remove Node.js and Yarn
sudo apt remove -y nodejs yarn

# Remove MongoDB (if installed)
sudo systemctl stop mongod
sudo apt remove -y mongodb-org
```

## Production Deployment

For production deployment, consider:

1. **Use a proper domain name** with SSL/TLS
2. **Configure firewall** properly (only open necessary ports)
3. **Set up log rotation** for application logs
4. **Configure MongoDB** with authentication (if using MongoDB)
5. **Set secure CORS_ORIGINS** in backend .env
6. **Use environment-specific .env** files
7. **Set up automated backups**
8. **Use a process manager** like PM2 or keep Supervisor
9. **Configure Nginx** with rate limiting and caching
10. **Set up monitoring** (e.g., Prometheus, Grafana)

### SSL/TLS with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate (replace your-domain.com)
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
sudo certbot renew --dry-run
```

## Support

For issues or questions:

1. Check the troubleshooting section above
2. View logs: `/var/log/supervisor/macmapping-*.log`
3. Check GitHub Issues: https://github.com/asherpoirier/macmapping/issues
4. Review README files in the repository

## System Requirements

- **OS**: Ubuntu 24.04 LTS (should work on 22.04 and 20.04 too)
- **RAM**: Minimum 2GB, Recommended 4GB
- **Disk**: Minimum 5GB free space
- **CPU**: 1 core minimum, 2+ recommended
- **Network**: Internet connection for downloading packages

## Security Notes

1. **Change default ports** if needed (edit .env files)
2. **Set up firewall** (UFW or iptables)
3. **Use strong passwords** for MongoDB (if enabled)
4. **Keep system updated**: `sudo apt update && sudo apt upgrade`
5. **Restrict CORS** in production (edit CORS_ORIGINS in backend/.env)
6. **Use HTTPS** in production
7. **Regular backups** of application data

## License

See the main repository for license information.
