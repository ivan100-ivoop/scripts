#!/usr/bin/env bash
set -e

URL="https://app.360monitoring.com/whitelist.php"

if command -v dnf >/dev/null 2>&1; then
  PKG=dnf
elif command -v yum >/dev/null 2>&1; then
  PKG=yum
else
  echo "No supported package manager found"
  exit 1
fi

for bin in curl ipcalc; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Installing $bin..."
    sudo $PKG install -y "$bin"
  fi
done

echo "Fetching 360Monitoring whitelist IPs..."
IPS=$(curl -s "$URL" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

if [ -z "$IPS" ]; then
  echo "No IPs found at $URL"
  exit 1
fi

echo "Whitelisting IPs in Imunify360..."
while read -r ip; do
  imunify360-agent ip-list local add --purpose white "$ip" || true
done <<< "$IPS"

echo "Done. Total IPs whitelisted: $(echo "$IPS" | wc -l)"
