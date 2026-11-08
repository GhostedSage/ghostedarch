#!/usr/bin/env bash
set -euo pipefail

# Ghosted Greeter Installation Script for Arch Linux / Ghosted Arch

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (e.g. sudo ./scripts/install.sh)" >&2
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    echo "==> Building release binary as user: ${SUDO_USER}..."
    sudo -u "${SUDO_USER}" cargo build --release
else
    echo "==> Building release binary..."
    cargo build --release
fi

echo "==> Installing binary to /usr/local/bin/ghosted-greeter..."
install -Dm755 target/release/ghosted-greeter /usr/local/bin/ghosted-greeter

echo "==> Installing configuration to /etc/ghosted/greeter.toml..."
install -dm755 /etc/ghosted
if [[ ! -f /etc/ghosted/greeter.toml ]]; then
    install -m644 ghosted-greeter.toml /etc/ghosted/greeter.toml
else
    echo "    /etc/ghosted/greeter.toml already exists, keeping current config."
    install -m644 ghosted-greeter.toml /etc/ghosted/greeter.toml.example
fi

echo "==> Installing assets and QML files to /usr/share/ghosted-greeter..."
install -dm755 /usr/share/ghosted-greeter/assets
install -dm755 /usr/share/ghosted-greeter/qml/components
install -dm755 /usr/share/ghosted-greeter/scripts

cp -r assets/* /usr/share/ghosted-greeter/assets/
cp -r qml/* /usr/share/ghosted-greeter/qml/
install -m755 scripts/start-greeter.sh /usr/share/ghosted-greeter/scripts/start-greeter.sh
install -m755 scripts/start-session.sh /usr/share/ghosted-greeter/scripts/start-session.sh

echo "==> Ensuring 'greeter' system user exists..."
if ! id -u greeter >/dev/null 2>&1; then
    useradd -r -M -d /var/lib/greetd -s /bin/false -G video,input,render greeter || true
else
    usermod -aG video,input,render greeter 2>/dev/null || true
fi
install -dm755 -o greeter -g greeter /var/lib/greetd 2>/dev/null || true

echo "==> Installing polkit rule for reboot/shutdown..."
install -dm755 /etc/polkit-1/rules.d
install -m644 packaging/40-ghosted-greeter.rules /etc/polkit-1/rules.d/40-ghosted-greeter.rules 2>/dev/null || true

echo "==> Installing silent console printk settings..."
install -Dm644 packaging/20-quiet-printk.conf /etc/sysctl.d/20-quiet-printk.conf 2>/dev/null || true
sysctl -p /etc/sysctl.d/20-quiet-printk.conf 2>/dev/null || true

echo "==> Installing greetd configuration..."
install -dm755 /etc/greetd
install -m644 packaging/greetd-config.toml /etc/greetd/config.toml

# Preserve live / custom wallpaper configuration if present
if [[ -f /var/tmp/ghosted/greeter.toml ]]; then
    cp /var/tmp/ghosted/greeter.toml /etc/ghosted/greeter.toml
elif [[ -f /etc/ghosted/greeter.toml ]]; then
    install -m644 ghosted-greeter.toml /etc/ghosted/greeter.toml
fi

echo "==> Setting permissions..."
chmod -R a+rx /usr/share/ghosted-greeter
chmod -R a+r /etc/ghosted
chmod 666 /etc/ghosted/greeter.toml 2>/dev/null || true

if systemctl list-unit-files greetd.service >/dev/null 2>&1; then
    echo "==> Enabling greetd.service..."
    systemctl enable greetd.service || true
fi

echo "==> Installation complete!"
echo "    To test in windowed mode: ghosted-greeter --demo"
echo "    Greetd and cage setup: verified"
echo "    Reboot to start Ghosted Greeter on VT1."
