#!/bin/bash

# Launch Gamescope with Steam
gamescope --backend headless -e -W 1280 -H 800 -r 60 -- "$@" -gamepadui -noverifyfiles &
GAMESCOPE_PID=\$!

# Wait for Gamescope to initialize
sleep 3

# Start Sunshine (will capture Gamescope via KMS)
/usr/local/bin/sunshine.AppImage &
SUNSHINE_PID=\$!

# Function to cleanup processes on exit
cleanup() {
    echo '[Entrypoint] Cleaning up processes...'
    kill \$GAMESCOPE_PID 2>/dev/null || true
    kill \$SUNSHINE_PID 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Wait for any process to exit
wait
