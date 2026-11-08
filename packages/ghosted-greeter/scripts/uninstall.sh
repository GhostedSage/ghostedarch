#!/usr/bin/env bash
set -euo pipefail

# Ghosted Greeter Uninstallation Script

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (e.g. sudo ./scripts/uninstall.sh)" >&2
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

echo "==> Removing Ghosted Greeter..."
rm -f /usr/local/bin/ghosted-greeter
rm -rf /usr/share/ghosted-greeter

echo "==> Removing configuration (/etc/ghosted)..."
rm -rf /etc/ghosted
rm -f /etc/sysctl.d/20-quiet-printk.conf

echo "==> Ghosted Greeter uninstalled successfully."
