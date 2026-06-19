#!/bin/bash
set -e

USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}
RENDER_GID=${RENDER_GID:-989}
INPUT_GID=${INPUT_GID:-993}

echo "[entry] UID=$USER_ID GID=$GROUP_ID RENDER_GID=$RENDER_GID INPUT_GID=$INPUT_GID"

# --- Fix UID/GID to match host ---
groupmod -o -g "$GROUP_ID" retro
usermod -o -u "$USER_ID" -g "$GROUP_ID" retro 2>/dev/null || true

# --- Hardware groups ---
groupmod -o -g "$RENDER_GID" render 2>/dev/null || groupadd -o -g "$RENDER_GID" render
groupmod -o -g "$INPUT_GID" input 2>/dev/null || groupadd -o -g "$INPUT_GID" input
usermod -aG render,video,audio,input retro

if [ -e /dev/uinput ]; then
    chgrp "$INPUT_GID" /dev/uinput 2>/dev/null || true
    chmod 0660 /dev/uinput 2>/dev/null || true
fi

# --- Runtime directories ---
export XDG_RUNTIME_DIR="/run/user/$USER_ID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export HOME="/home/retro"
export USER="retro"

mkdir -p "$XDG_RUNTIME_DIR" /run/dbus "$HOME/.local/state/wireplumber"
chown "$USER_ID":"$GROUP_ID" "$XDG_RUNTIME_DIR" /run/dbus
chmod 700 "$XDG_RUNTIME_DIR"
chown -R "$USER_ID":"$GROUP_ID" "$HOME/.local/state"
chown "$USER_ID":"$GROUP_ID" "$HOME"

# --- Clean stale locks ---
rm -f "$HOME/.local/share/Steam"/{steam.pid,steam.pipe,.registry.vdf.lock} 2>/dev/null || true

# --- Start services ---
dbus-daemon --system --fork
rm -f /run/dbus/pid 2>/dev/null || true
runuser -u retro -- dbus-daemon --session --fork --address="$DBUS_SESSION_BUS_ADDRESS"
runuser -u retro -- pipewire &
runuser -u retro -- wireplumber &
runuser -u retro -- pipewire-pulse &
sleep 2

# --- Launch command as unprivileged user ---
exec runuser -u retro -- "$@"
