#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                   GHOSTEDLAND — STANDALONE SESSION LAUNCHER                ║
# ║                                                                            ║
# ║  Launches GhostedLand as a primary login session from display managers.    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

if [ "$1" = "dispatch" ]; then
    shift
    exec ghostedctl dispatch "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/target/debug"
COMPOSITOR_BUILD_DIR="${SCRIPT_DIR}/compositor/ghosted-compositor/build"
if [ -n "${GHOSTEDLAND_CONFIG:-}" ] && [ -f "${GHOSTEDLAND_CONFIG}" ]; then
    CONFIG_FILE="${GHOSTEDLAND_CONFIG}"
elif [ -n "${GHOSTED_CONFIG:-}" ] && [ -f "${GHOSTED_CONFIG}" ]; then
    CONFIG_FILE="${GHOSTED_CONFIG}"
elif [ -f "${HOME}/.config/ghostedland/ghostedland.lua" ]; then
    CONFIG_FILE="${HOME}/.config/ghostedland/ghostedland.lua"
elif [ -f "${HOME}/.local/share/ghostedland/ghostedland.lua" ]; then
    CONFIG_FILE="${HOME}/.local/share/ghostedland/ghostedland.lua"
elif [ -f "${SCRIPT_DIR}/config/ghostedland.lua" ]; then
    CONFIG_FILE="${SCRIPT_DIR}/config/ghostedland.lua"
elif [ -f "/usr/local/share/ghostedland/ghostedland.lua" ]; then
    CONFIG_FILE="/usr/local/share/ghostedland/ghostedland.lua"
elif [ -f "/usr/share/ghostedland/ghostedland.lua" ]; then
    CONFIG_FILE="/usr/share/ghostedland/ghostedland.lua"
elif [ -f "${SCRIPT_DIR}/config/ghostedland.conf" ]; then
    CONFIG_FILE="${SCRIPT_DIR}/config/ghostedland.conf"
fi

# Record session launch milestone if not already provided by greeter
export GHOSTED_SESSION_START_MS="${GHOSTED_SESSION_START_MS:-$(date +%s%3N)}"
export GHOSTED_AUTH_TIMESTAMP_MS="${GHOSTED_AUTH_TIMESTAMP_MS:-${GHOSTED_SESSION_START_MS}}"

export XDG_CURRENT_DESKTOP="GhostedLand:Hyprland"
export XDG_SESSION_DESKTOP="GhostedLand"
export XDG_SESSION_TYPE="wayland"
export PATH="${COMPOSITOR_BUILD_DIR}:${BIN_DIR}:${SCRIPT_DIR}/target/release:${SCRIPT_DIR}/target/debug:${HOME}/.local/bin:/usr/local/bin:${PATH}"

# Per-user overrides first (KEY=value lines), so they always win over detection.
SESSION_ENV="${HOME}/.config/ghostedland/session.env"
if [ -f "${SESSION_ENV}" ]; then
    set -a
    # shellcheck source=/dev/null
    . "${SESSION_ENV}"
    set +a
fi

# Detect GPUs on every login (hybrid ordering, NVIDIA, VMs) so the session
# adapts when hardware changes. Detection never overrides values set above.
if command -v ghostedland-hwdetect >/dev/null 2>&1; then
    HWDETECT="ghostedland-hwdetect"
elif [ -x "${SCRIPT_DIR}/ghostedland-hwdetect.sh" ]; then
    HWDETECT="${SCRIPT_DIR}/ghostedland-hwdetect.sh"
fi
# Set GHOSTED_NO_HWDETECT=1 (e.g. in session.env) to disable detection entirely.
if [ -n "${HWDETECT:-}" ] && [ "${GHOSTED_NO_HWDETECT:-0}" != 1 ]; then
    eval "$("${HWDETECT}" --env 2>/dev/null)"
    if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then
        "${HWDETECT}" --report > "${XDG_RUNTIME_DIR}/ghostedland-hardware.txt" 2>/dev/null || true
    fi
fi

# Crash-loop protection: detect rapid restarts (>= 3 crashes within 60s)
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then
    CRASH_LOG="${XDG_RUNTIME_DIR}/ghosted-crash-history.log"
else
    CRASH_LOG="/tmp/ghosted-crash-history-${USER:-$(id -u)}.log"
fi

NOW=$(date +%s)
SAFE_MODE_ARGS=()

if [ -f "${CRASH_LOG}" ]; then
    # Keep timestamps within the last 60 seconds
    RECENT_CRASHES=()
    while read -r ts; do
        if [ -n "${ts}" ] && [ "$((NOW - ts))" -le 60 ]; then
            RECENT_CRASHES+=("${ts}")
        fi
    done < "${CRASH_LOG}"

    if [ "${#RECENT_CRASHES[@]}" -ge 2 ]; then
        echo "[GhostedLand Launcher] WARNING: Rapid crash loop detected (${#RECENT_CRASHES[@]} crashes in last 60s). Activating Emergency Safe Mode." >&2
        SAFE_MODE_ARGS=("--safe-mode")
    fi
    printf "%s\n" "${RECENT_CRASHES[@]}" > "${CRASH_LOG}" 2>/dev/null || true
fi
echo "${NOW}" >> "${CRASH_LOG}"

if [ -x "${COMPOSITOR_BUILD_DIR}/ghostedland-compositor" ]; then
    exec "${COMPOSITOR_BUILD_DIR}/ghostedland-compositor" ${CONFIG_FILE:+-c "$CONFIG_FILE"} "${SAFE_MODE_ARGS[@]}" "$@"
elif command -v Hyprland >/dev/null 2>&1; then
    exec Hyprland ${CONFIG_FILE:+-c "$CONFIG_FILE"} "${SAFE_MODE_ARGS[@]}" "$@"
elif command -v hyprland >/dev/null 2>&1; then
    exec hyprland ${CONFIG_FILE:+-c "$CONFIG_FILE"} "${SAFE_MODE_ARGS[@]}" "$@"
elif command -v ghosted-compositor >/dev/null 2>&1; then
    exec ghosted-compositor ${CONFIG_FILE:+-c "$CONFIG_FILE"} "${SAFE_MODE_ARGS[@]}" "$@"
elif command -v ghostedland-compositor >/dev/null 2>&1; then
    exec ghostedland-compositor ${CONFIG_FILE:+-c "$CONFIG_FILE"} "${SAFE_MODE_ARGS[@]}" "$@"
else
    echo "[GhostedLand Launcher] ERROR: No Wayland compositor found (Hyprland or ghosted-compositor)!" >&2
    exit 1
fi

