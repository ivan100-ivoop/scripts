#!/bin/bash
# Script to reset and reinstall agent360 monitoring

# Exit immediately if a command fails
set -e

# Get current date
DATE=$(date +%Y%m%d)

echo "==> Moving the invalid token file..."
if [ -f /etc/agent360-token.ini ]; then
    mv -v /etc/agent360-token.ini{,.$DATE}
else
    echo "No token file found, skipping..."
fi

echo "==> Moving the data directory..."
if [ -d /root/.360monitoring ]; then
    mv -v /root/.360monitoring{,.$DATE}
else
    echo "No data directory found, skipping..."
fi

echo "==> Moving the systemd service file..."
if [ -f /etc/systemd/system/agent360.service ]; then
    mv -v /etc/systemd/system/agent360.service{,.$DATE}
else
    echo "No systemd service file found, skipping..."
fi

echo "==> Reloading systemd configuration..."
systemctl daemon-reload

echo "==> Reinstalling cpanel-monitoring-plugin package..."
dnf reinstall -y cpanel-monitoring-plugin

echo "==> Initializing agent360 monitoring plugin..."
/scripts/initialize_360monitoring

echo "==> Restarting agent360 service..."
systemctl restart agent360.service

echo "==> Restarting agent360 service again (double check)..."
systemctl restart agent360.service

echo "==> All done!"
