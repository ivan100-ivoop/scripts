#!/bin/bash
echo "===== SECURITY CHECK ====="
echo "Server: $(hostname -f 2>/dev/null || hostname)"
echo "Date: $(date)"
echo "OS: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')"
echo "cPanel: $(/usr/local/cpanel/cpanel -V 2>/dev/null || echo 'not installed')"
echo "Running kernel: $(uname -r)"
echo
echo "KernelCare:"
if command -v kcarectl >/dev/null 2>&1; then
  kcarectl --info
  echo
  echo "Dirty Frag / CVE check:"
  kcarectl --patch-info 2>/dev/null | grep -Ei 'CVE-2026-43284|CVE-2026-43500|Dirty Frag|dirtyfrag' || echo "Not shown explicitly"
else
  echo "Not installed"
fi
echo
echo "Loaded modules:"
lsmod | grep -E '^(esp4|esp6|rxrpc)' || echo "esp4/esp6/rxrpc not loaded"
echo
echo "Installed kernels:"
rpm -qa | grep -E '^kernel(-core|-modules)?-[0-9]|^kernel-[0-9]' | sort -V | tail -10
echo "===== END ====="
