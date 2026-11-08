#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                   GHOSTEDLAND — NESTED SESSION LAUNCHER                    ║
# ║                                                                            ║
# ║  Runs Ghostedland in a nested Wayland window inside your current session.  ║
# ║  Allows testing the compositor, bar, and settings app safely in a sandbox. ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/target/debug"
if [ -n "${GHOSTED_CONFIG:-}" ] && [ -f "${GHOSTED_CONFIG}" ]; then
    CONFIG_FILE="${GHOSTED_CONFIG}"
elif [ -f "${SCRIPT_DIR}/config/ghostedland.lua" ]; then
    CONFIG_FILE="${SCRIPT_DIR}/config/ghostedland.lua"
elif [ -f "${SCRIPT_DIR}/config/ghostedland.conf" ]; then
    CONFIG_FILE="${SCRIPT_DIR}/config/ghostedland.conf"
fi

# Ensure all Ghosted binaries are in PATH
COMPOSITOR_BUILD_DIR="${SCRIPT_DIR}/compositor/ghosted-compositor/build"
export PATH="${COMPOSITOR_BUILD_DIR}:${BIN_DIR}:${SCRIPT_DIR}/target/release:${SCRIPT_DIR}/target/debug:${HOME}/.local/bin:/usr/local/bin:${PATH}"

# Ensure config directory exists
mkdir -p "${HOME}/.config/ghosted"

echo "=================================================="
echo " Starting Ghostedland (Nested Test Environment)..."
echo "=================================================="
echo " Binaries dir : ${BIN_DIR}"
echo " Config file  : ${CONFIG_FILE}"
echo ""
echo " Keybindings inside the nested window:"
echo "   • Super + Enter   : Terminal (kitty)"
echo "   • Super + S / I   : Ghosted Settings GUI"
echo "   • Super + Space/D : App Launcher (wofi/rofi)"
echo "   • Super + Q       : Close active window"
echo "   • Super + M /     :"
echo "     Super+Shift+Q   : Exit nested session"
echo "=================================================="

# Run GhostedLand compositor with custom Ghosted configuration

if [ -x "${SCRIPT_DIR}/target/release/ghosted-compositor" ]; then
    exec "${SCRIPT_DIR}/target/release/ghosted-compositor" --nested ${CONFIG_FILE:+-c "$CONFIG_FILE"}
elif [ -x "${SCRIPT_DIR}/target/debug/ghosted-compositor" ]; then
    exec "${SCRIPT_DIR}/target/debug/ghosted-compositor" --nested ${CONFIG_FILE:+-c "$CONFIG_FILE"}
elif command -v ghosted-compositor >/dev/null 2>&1; then
    exec ghosted-compositor --nested ${CONFIG_FILE:+-c "$CONFIG_FILE"}
elif [ -x "${COMPOSITOR_BUILD_DIR}/ghostedland-compositor" ]; then
    exec "${COMPOSITOR_BUILD_DIR}/ghostedland-compositor" -c "${CONFIG_FILE}"
elif command -v ghostedland-compositor >/dev/null 2>&1; then
    exec ghostedland-compositor -c "${CONFIG_FILE}"
else
    echo "[GhostedLand Launcher] ERROR: ghosted-compositor binary not found!" >&2
    exit 1
fi

