#!/bin/bash

ALLOWED_IPS=(
  109.120.234.50
  109.120.246.3
  93.94.140.27
  93.94.140.28
  93.94.140.29
  93.94.140.30
  93.94.140.31
  93.94.140.32
  93.94.140.33
  93.94.140.34
  93.94.140.35
  93.94.140.36
  93.94.140.37
  93.94.140.71
  93.94.140.121
  93.94.140.42
  93.94.140.25
  93.94.140.133
  93.94.140.17
  93.94.140.15
)

for IP in "${ALLOWED_IPS[@]}"; do
  iptables -A INPUT -p tcp -s "$IP" --dport 2087 -j ACCEPT
  iptables -A INPUT -p tcp -s "$IP" --dport 2083 -j ACCEPT
done

# Block everyone else on these ports
iptables -A INPUT -p tcp --dport 2087 -j DROP
iptables -A INPUT -p tcp --dport 2083 -j DROP

echo "Done. Current INPUT chain:"
iptables -L INPUT -n --line-numbers
