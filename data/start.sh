#!/bin/bash

# Launch Gamescope with specified app (use full path for reliability)

gamescope --backend headless -e -W 1280 -H 800 -r 60 -- "$@" &
GAMESCOPE_PID=\$!

# Wait for Gamescope to initialize
sleep 3
wayvnc 0.0.0.0

# # Start Sunshine (Ubuntu 24.04 binary)
# if [ -x /usr/bin/sunshine ]; then
#     echo '[Start Script] Starting Sunshine'
#     /usr/bin/sunshine &
# else
#     echo '[Start Script] ERROR: Sunshine not found!'
# fi
# SUNSHINE_PID=$!
# SUNSHINE_PID=\$!
#
# # Function to cleanup processes on exit
# cleanup() {
#     echo '[Entrypoint] Cleaning up processes...'
#     kill \$GAMESCOPE_PID 2>/dev/null || true
#     kill \$SUNSHINE_PID 2>/dev/null || true
#     exit 0
# }
#
# # Set up signal handlers
# trap cleanup SIGTERM SIGINT
#
# # Wait for any process to exit
# wait
