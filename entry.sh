#!/bin/bash
set -e

USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}
RENDER_GID=${RENDER_GID:-989}

echo "[Entrypoint] Setting up environment for UID: $USER_ID / GID: $GROUP_ID..."

# --- 1. USER/GROUP SETUP ---
if ! getent group retro > /dev/null 2>&1; then
    groupadd -g "$GROUP_ID" retro
else
    groupmod -o -g "$GROUP_ID" retro
fi

if ! id -u retro > /dev/null 2>&1; then
    useradd -u "$USER_ID" -g "$GROUP_ID" -m -s /bin/bash retro
else
    usermod -o -u "$USER_ID" -g "$GROUP_ID" retro 2>/dev/null || true
fi

# --- 2. HARDWARE ACCESS ---
if getent group render > /dev/null 2>&1; then
    groupmod -o -g "$RENDER_GID" render
else
    groupadd -o -g "$RENDER_GID" render
fi
usermod -aG render retro
usermod -aG video retro
groupadd -f audio
usermod -aG audio retro

# groupadd -g 993 host_input
# usermod -aG host_input retro

# --- 3. RUNTIME DIR FIXES ---
mkdir -p /run/user/"$USER_ID"
chown "$USER_ID":"$GROUP_ID" /run/user/"$USER_ID"
chown -R "$USER_ID":"$GROUP_ID" /home/retro
chmod 700 /run/user/"$USER_ID"

mkdir -p /run/dbus
chown "$USER_ID":"$GROUP_ID" /run/dbus
rm -f /run/dbus/pid 2>/dev/null || true

# --- 4. CLEANUP LOCKS ---
rm -f /home/retro/.local/share/Steam/steam.pid 2>/dev/null || true
rm -f /home/retro/.local/share/Steam/steam.pipe 2>/dev/null || true
rm -f /home/retro/.local/share/Steam/.registry.vdf.lock 2>/dev/null || true

# --- 5. START INTERNAL SERVICES ---
echo "[Entrypoint] Starting internal DBus and Audio Stack..."

# Start System DBus (Required for PipeWire)
dbus-daemon --system --fork

# Export runtime vars for the user
export XDG_RUNTIME_DIR=/run/user/"$USER_ID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# Switch to user 'retro' to start the user-level audio services
su retro -c "
    # 1. Start Session DBus
    dbus-daemon --session --fork --address=$DBUS_SESSION_BUS_ADDRESS

    # 2. Start PipeWire (The Core)
    pipewire &

    # 3. Start WirePlumber (The Session Manager)
    wireplumber &

    # 4. Start PipeWire-Pulse (The Compatibility Layer for Steam)
    pipewire-pulse &
"

# Give them a second to initialize
sleep 2

export HOME="/home/retro"
export USER="retro"
# export WAYLAND_DISPLAY=gamescope-0

# 3. Drop privileges
exec runuser -u retro -- "$@"
