#!/usr/bin/env bash
# Ghosted Greeter - Silent Greeter Launcher
# Prevents any terminal text, cursor, or compositor debug logs from appearing on screen.

# 1. Clear VT, move cursor to 0,0, and hide console cursor
printf '\033[2J\033[H\033[?25l'
setterm -cursor off -blank 0 2>/dev/null || true

# 2. Launch Cage kiosk compositor with ghosted-greeter
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
exec cage -s -- "${GREETER_BIN}" >"${LOG_FILE}" 2>&1

