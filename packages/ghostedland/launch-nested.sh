#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                   GHOSTEDLAND — NESTED SESSION LAUNCHER                    ║
# ║                                                                            ║
# ║  Runs Ghostedland in a nested Wayland window inside your current session.  ║
# ║  Allows testing the compositor, bar, and settings app safely in a sandbox. ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/target/debug"

# Optional config override: a config.toml file or the directory holding it.
CONFIG_ARGS=()
CONFIG_FILE="${HOME}/.config/ghosted/config.toml"
if [ -n "${GHOSTED_CONFIG:-}" ] && { [ -d "${GHOSTED_CONFIG}" ] || [[ "${GHOSTED_CONFIG}" == *.toml && -f "${GHOSTED_CONFIG}" ]]; }; then
    CONFIG_FILE="${GHOSTED_CONFIG}"
    CONFIG_ARGS=(--config "${GHOSTED_CONFIG}")
fi

# Ensure all Ghosted binaries are in PATH
export PATH="${SCRIPT_DIR}/target/release:${BIN_DIR}:${HOME}/.local/bin:/usr/local/bin:${PATH}"

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

# Run the GhostedLand compositor in a window

if ! command -v ghosted-compositor >/dev/null 2>&1; then
    echo "[GhostedLand Launcher] ERROR: ghosted-compositor binary not found!" >&2
    echo "  Build it with: cargo build -p ghosted-compositor" >&2
    exit 1
fi

exec ghosted-compositor --nested "${CONFIG_ARGS[@]}" "$@"
