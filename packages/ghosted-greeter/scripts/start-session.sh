#!/usr/bin/env bash
# Ghosted Greeter - Silent Desktop Session Launcher
# Ensures the handover between Greeter and GhostedLand is seamless without any terminal flashing or code output.

# 1. Capture high-precision authentication completion timestamp for latency benchmarking
export GHOSTED_AUTH_TIMESTAMP_MS=$(date +%s%3N)

# 2. Clear VT and ensure cursor remains hidden
printf '\033[2J\033[H\033[?25l'
setterm -cursor off -blank 0 2>/dev/null || true

# Prefer a locally installed GhostedLand over an older packaged copy in /usr/bin.
export PATH="/usr/local/bin:${PATH}"

# 3. Determine session command (preferring start-ghostedland)
if [ $# -gt 0 ]; then
    SESSION_CMD=("$@")
elif command -v start-ghostedland >/dev/null 2>&1; then
    SESSION_CMD=("start-ghostedland")
elif [ -x "$(dirname "$0")/../../start-ghostedland.sh" ]; then
    SESSION_CMD=("$(cd "$(dirname "$0")/../.." && pwd)/start-ghostedland.sh")
else
    SESSION_CMD=("start-ghostedland")
fi

# 4. Launch desktop session silently
# Redirect stdout and stderr so compositor startup banner and logs don't hit the TTY console.
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then
    LOG_FILE="${XDG_RUNTIME_DIR}/ghostedland-session.log"
else
    LOG_FILE="/tmp/ghostedland-session-${USER:-$(id -u)}.log"
fi
exec "${SESSION_CMD[@]}" >"${LOG_FILE}" 2>&1

