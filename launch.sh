#!/bin/bash
set -e

# --- Read resolution from config ---
RES_FILE="/app/config/res.txt"
if [ -f "$RES_FILE" ]; then
    RES=$(cat "$RES_FILE")
else
    RES="1280x800"
fi
W=${RES%x*}
H=${RES#*x}

# --- Launch gamescope wrapping the requested command ---
exec gamescope --backend headless -e -W "$W" -H "$H" -w "$W" -h "$H" -r 60 -- "$@"
