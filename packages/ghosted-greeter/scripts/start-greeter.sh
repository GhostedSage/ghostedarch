#!/usr/bin/env bash
# Ghosted Greeter - Silent Greeter Launcher
# Prevents any terminal text, cursor, or compositor debug logs from appearing on screen.

# 1. Clear VT, move cursor to 0,0, and hide console cursor
printf '\033[2J\033[H\033[?25l'
setterm -cursor off -blank 0 2>/dev/null || true

# 2. Launch the greeter inside a kiosk compositor.
# Redirect all stdout/stderr to a log file so no logs are written to the console
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then
    LOG_FILE="${XDG_RUNTIME_DIR}/ghosted-greeter.log"
else
    LOG_FILE="/tmp/ghosted-greeter-${USER:-$(id -u)}.log"
fi
GREETER_BIN="ghosted-greeter"
if [ -x "/var/tmp/ghosted/bin/ghosted-greeter" ]; then
    GREETER_BIN="/var/tmp/ghosted/bin/ghosted-greeter"
fi

# The login screen runs on GhostedLand's own compositor in kiosk mode: one
# fullscreen application, no keybindings, no control socket. If it cannot
# start (it exits with an error within 5 seconds) we fall back to cage when
# that is installed, so a compositor problem never locks you out of logging in.
# Set GHOSTED_GREETER_COMPOSITOR=cage (e.g. in /etc/environment) to force cage.
# Prefer a locally installed build over an older packaged one, and only use a
# compositor that actually has kiosk mode.
export PATH="/usr/local/bin:${PATH}"
if [ "${GHOSTED_GREETER_COMPOSITOR:-auto}" != "cage" ] \
    && command -v ghosted-compositor >/dev/null 2>&1 \
    && ghosted-compositor --help 2>/dev/null | grep -q -- "--kiosk"; then
    STARTED=$(date +%s)
    ghosted-compositor --backend drm --kiosk "${GREETER_BIN}" >"${LOG_FILE}" 2>&1
    RC=$?
    if [ "${RC}" -eq 0 ] || [ "$(( $(date +%s) - STARTED ))" -ge 5 ] || ! command -v cage >/dev/null 2>&1; then
        exit "${RC}"
    fi
    echo "[start-greeter] ghosted-compositor failed (exit ${RC}); falling back to cage" >>"${LOG_FILE}"
    exec cage -s -- "${GREETER_BIN}" >>"${LOG_FILE}" 2>&1
fi

exec cage -s -- "${GREETER_BIN}" >"${LOG_FILE}" 2>&1
