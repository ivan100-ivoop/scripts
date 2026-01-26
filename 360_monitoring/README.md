# 360 Monitoring Plugin – Troubleshooting Guide

## Short Command
```bash
curl -sSL https://raw.githubusercontent.com/ivan100-ivoop/scripts/refs/heads/main/360_monitoring/fix.sh | sudo bash
```

## Symptoms
After installing the **360 Monitoring** software on your server, you may encounter the following issues:  

1. The application fails to load any information, and you may see the following error in a dialog box:  

```text
Error: [POST] "https://api.monitoring360.io/metrics/get-metrics-data": 404
```

2. The **Sign Up** button does not complete the sign-in process. Completing the sign-in may loop you back to the initial **Sign Up** page.  

---

## Description
These issues can occur if the 360 Monitoring application is **missing configuration information** required for the cPanel version of the plugin. This typically happens if the plugin was installed incorrectly.  

To address this, we provide an **initialization script** for cPanel that ensures the plugin is installed and configured properly.  

---

## Workaround
To resolve these issues, perform the following steps:  

1. **Move the invalid token file**:  
```bash
mv -v /etc/agent360-token.ini{,.$(date +%Y%m%d)}
```

2. **Move the existing data directory**:  
```bash
mv -v /root/.360monitoring{,.$(date +%Y%m%d)}
```

3. **Move the systemd service file**:  
```bash
mv -v /etc/systemd/system/agent360.service{,.$(date +%Y%m%d)}
```

4. **Reload systemd configuration**:  
```bash
systemctl daemon-reload
```

5. **Reinstall the cPanel monitoring plugin**:  
```bash
dnf reinstall -y cpanel-monitoring-plugin
```

6. **Run the initialization script for the 360 Monitoring plugin**:  
```bash
/scripts/initialize_360monitoring
```

7. **Restart the monitoring service**:  
```bash
systemctl restart agent360.service
systemctl restart agent360.service  # Run twice to ensure service restarts properly
```

---

## Notes
- Backups of files and directories are automatically suffixed with the current date (YYYYMMDD).  
- Ensure you have root or sudo privileges to perform these steps.  
- After completing the workaround, the plugin should load metrics correctly, and the sign-in process should work as expected.  
- This information is based on guidance from cPanel: [cPanel 360 Monitoring Plugin Not Displaying Data After Installation](https://support.cpanel.net/hc/en-us/articles/30814926304151-cPanel-360-monitoring-plugin-not-displaying-data-after-installation)
