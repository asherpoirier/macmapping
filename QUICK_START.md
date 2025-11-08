# Quick Start Guide

## Installation (One Command)

```bash
sudo apt update && sudo apt install -y git && \
git clone https://github.com/asherpoirier/macmapping.git /tmp/macmapping && \
sudo bash /tmp/macmapping/install-ubuntu.sh
```

## Accessing the App

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001/api/

## Service Control

```bash
cd /var/www/html/macmapping

# Start
./start.sh

# Stop
./stop.sh

# Restart
./restart.sh

# Status
./status.sh

# Logs
./logs.sh
```

## Quick Test

```bash
# Test backend
curl http://localhost:8001/api/

# Open frontend in browser
xdg-open http://localhost:3000  # Linux
open http://localhost:3000       # Mac
```

## Troubleshooting

### View Logs
```bash
# Backend
tail -f /var/log/supervisor/macmapping-backend.err.log

# Frontend
tail -f /var/log/supervisor/macmapping-frontend.out.log
```

### Check Status
```bash
sudo supervisorctl status
```

### Restart Services
```bash
sudo supervisorctl restart macmapping-backend macmapping-frontend
```

## File Locations

- **Application**: `/var/www/html/macmapping/`
- **Backend Config**: `/var/www/html/macmapping/backend/.env`
- **Frontend Config**: `/var/www/html/macmapping/frontend/.env`
- **Logs**: `/var/log/supervisor/macmapping-*.log`
- **Nginx Config**: `/etc/nginx/sites-available/macmapping`

## Common Commands

```bash
# Update application
cd /var/www/html/macmapping
git pull
sudo supervisorctl restart macmapping-backend macmapping-frontend

# View running processes
sudo supervisorctl

# Check ports
sudo netstat -tulpn | grep -E ':(3000|8001)'

# Fix permissions
sudo chown -R $USER:$USER /var/www/html/macmapping
```

## Need Help?

See full documentation: `INSTALL_UBUNTU.md`
