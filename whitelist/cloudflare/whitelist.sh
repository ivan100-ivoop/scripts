#!/usr/bin/env bash
set -e

URL="https://www.cloudflare.com/ips-v4"

if command -v dnf >/dev/null 2>&1; then
  PKG=dnf
elif command -v yum >/dev/null 2>&1; then
  PKG=yum
else
  echo "No supported package manager found"
  exit 1
fi

for bin in curl; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Installing $bin..."
    sudo $PKG install -y "$bin"
  fi
done

echo "Fetching Cloudflare IP ranges..."

IPS=$(curl -s "$URL")

if [ -z "$IPS" ]; then
  echo "No IPs found"
  exit 1
fi

echo "Whitelisting Cloudflare IPs in Imunify360..."

while read -r ip; do
  [ -z "$ip" ] && continue
  imunify360-agent ip-list local add --purpose white "$ip" || true
done <<< "$IPS"

echo "Done. Total IP ranges whitelisted: $(echo "$IPS" | wc -l)"
