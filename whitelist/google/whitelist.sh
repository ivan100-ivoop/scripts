#!/usr/bin/env bash
set -e

URLS=(
  "https://developers.google.com/static/search/apis/ipranges/special-crawlers.json"
  "https://developers.google.com/static/search/apis/ipranges/user-triggered-fetchers.json"
  "https://developers.google.com/static/search/apis/ipranges/user-triggered-fetchers-google.json"
  "https://developers.google.com/static/search/apis/ipranges/googlebot.json"
)

# Detect package manager
if command -v dnf >/dev/null 2>&1; then
  PKG=dnf
elif command -v yum >/dev/null 2>&1; then
  PKG=yum
else
  echo "❌ No supported package manager found"
  exit 1
fi

# Auto install dependencies
for bin in curl jq ipcalc; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Installing $bin..."
    sudo $PKG install -y "$bin"
  fi
done

echo "Fetching Google IPv4 CIDR ranges..."
> list.txt

for url in "${URLS[@]}"; do
  curl -s "$url" \
    | jq -r '.prefixes[] | select(.ipv4Prefix != null) | .ipv4Prefix' \
    >> list.txt
done

# Clean + dedupe
sort -u -o list.txt list.txt

echo "Done."
echo "Total IPv4 CIDRs: $(wc -l < list.txt)"

cat list.txt | xargs -n 1 imunify360-agent ip-list local add --purpose white
rm list.txt
