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

# Optional config override: a config.toml file or the directory holding it.
# Without it the compositor reads ~/.config/ghosted/config.toml.
CONFIG_ARGS=()
for candidate in "${GHOSTEDLAND_CONFIG:-}" "${GHOSTED_CONFIG:-}"; do
    if [ -n "${candidate}" ] && { [ -d "${candidate}" ] || [[ "${candidate}" == *.toml && -f "${candidate}" ]]; }; then
        CONFIG_ARGS=(--config "${candidate}")
        break
    fi
done

# Record session launch milestone if not already provided by greeter
export GHOSTED_SESSION_START_MS="${GHOSTED_SESSION_START_MS:-$(date +%s%3N)}"
export GHOSTED_AUTH_TIMESTAMP_MS="${GHOSTED_AUTH_TIMESTAMP_MS:-${GHOSTED_SESSION_START_MS}}"

export XDG_CURRENT_DESKTOP="GhostedLand"
export XDG_SESSION_DESKTOP="GhostedLand"
export XDG_SESSION_TYPE="wayland"
export PATH="${SCRIPT_DIR}/target/release:${BIN_DIR}:${SCRIPT_DIR}/target/debug:${HOME}/.local/bin:/usr/local/bin:${PATH}"

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

# Self-heal the per-user portal config: one seeded by the old Hyprland-based
# session names the hyprland backend, which cannot work here and would break
# screen sharing. Replace it with the shipped config (keeping a backup).
USER_PORTALS="${XDG_CONFIG_HOME:-${HOME}/.config}/xdg-desktop-portal/ghostedland-portals.conf"
if [ -f "${USER_PORTALS}" ] && grep -qi "hyprland" "${USER_PORTALS}" 2>/dev/null; then
    for shipped in "/usr/share/xdg-desktop-portal/ghostedland-portals.conf" \
                   "/usr/local/share/xdg-desktop-portal/ghostedland-portals.conf" \
                   "${SCRIPT_DIR}/config/ghostedland-portals.conf"; do
        if [ -f "${shipped}" ] && ! grep -qi "hyprland" "${shipped}" 2>/dev/null; then
            cp -f "${USER_PORTALS}" "${USER_PORTALS}.bak" 2>/dev/null
            cp -f "${shipped}" "${USER_PORTALS}" 2>/dev/null \
                && echo "[GhostedLand Launcher] Migrated portal config to the wlr backend." >&2
            break
        fi
    done
fi

# GhostedLand runs on its own native compositor; no other compositor is needed.
if ! command -v ghosted-compositor >/dev/null 2>&1; then
    echo "[GhostedLand Launcher] ERROR: ghosted-compositor not found in PATH." >&2
    echo "  Build it with: cargo build --release -p ghosted-compositor" >&2
    exit 1
fi

exec ghosted-compositor --backend drm "${CONFIG_ARGS[@]}" "${SAFE_MODE_ARGS[@]}" "$@"
