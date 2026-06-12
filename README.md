# Steam Dockerized

Run Steam in a Docker container with [Gamescope](https://github.com/ValveSoftware/gamescope) for headless game streaming via Steam Remote Play.

The container runs Steam in SteamOS/Game Mode (`-steamos3 -gamepadui`) inside a headless Gamescope session — no monitor, no desktop environment, no X server on the host required. Connect to it from any Steam client on your network using Remote Play.

## Requirements

- **Linux host** with Docker and Docker Compose
- **AMD or NVIDIA GPU** (see [GPU Selection](#gpu-selection) below)
- **Steam** installed on a client device for Remote Play

## Quick Start

### 1. Clone and configure

```bash
git clone <repo-url> steam-dockerized
cd steam-dockerized
cp compose.override.yml.example compose.override.yml
```

Edit `compose.override.yml` to match your system:

```yaml
services:
  steam:
    restart: unless-stopped

    environment:
      - PUID=1000        # Your user ID  (run `id -u`)
      - PGID=1000        # Your group ID (run `id -g`)
      - RENDER_GID=989   # run `getent group render | cut -d: -f3`
      - TZ=America/Denver

    volumes:
      # Your Steam installation — games, saves, and config persist here
      - ${HOME}/.local/share/Steam:/home/retro/.local/share/Steam

      # Additional game library paths:
      # - /mnt/games/SteamLibrary:/mnt/games/SteamLibrary
```

### 2. Set up input device permissions

Steam Remote Play needs access to create virtual input devices. Run once:

```bash
make rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 3. Build and start

```bash
docker compose build
docker compose up
```

Steam will launch in headless Game Mode. Open Steam on another device on the same network, and your dockerized instance will appear as a streamable machine under Remote Play.

## Project Structure

```
├── Dockerfile                       # Multi-stage build (base → amd/nvidia/debug)
├── compose.yml                      # Generic container config
├── compose.override.yml.example     # Template for host-specific settings
├── compose.override.yml             # Your local overrides (gitignored)
├── entry.sh                         # Container entrypoint
├── data/                            # Persistent config (gitignored)
│   └── .config/                     # Steam/app configuration
└── Makefile                         # Convenience targets
```

## Configuration

### Environment Variables

Set these in your `compose.override.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | UID of the container user (match your host user) |
| `PGID` | `1000` | GID of the container user (match your host group) |
| `RENDER_GID` | `989` | GID of the host `render` group (for GPU access) |
| `TZ` | — | Timezone (e.g. `America/Denver`) |

### Volume Mounts

The base `compose.yml` mounts everything the container needs to function. Your override file adds the host-specific paths:

| Mount | Purpose |
|-------|---------|
| `~/.local/share/Steam:/home/retro/.local/share/Steam` | Steam games, saves, and runtime data |
| Additional library paths | Any extra Steam Library folders on other drives |

> [!IMPORTANT]
> Docker Compose **merges** list values (`volumes`, `environment`) from the override file with the base — they are additive, not replacements.

### GPU Selection

The Dockerfile provides separate stages for AMD and NVIDIA GPUs. The default target is `amd`.

**AMD (default)** — no changes needed, just ensure your override has:

```yaml
environment:
  - AMD_VULKAN_ICD=RADV
```

**NVIDIA** — add the following to your `compose.override.yml`:

```yaml
services:
  steam:
    build:
      context: .
      target: nvidia
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
```

> [!NOTE]
> NVIDIA requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed on the host.

### Gamescope Options

The default command launches at 1280×800 @ 60fps:

```yaml
command: gamescope --backend headless -e -W 1280 -H 800 -r 60 -- steam -steamos3 -gamepadui
```

Override `command` in your `compose.override.yml` to change resolution or framerate. Unlike list values, `command` is a scalar and **replaces** the base value.

## Debug Image

The Dockerfile includes a `debug` stage that adds [Sway](https://swaywm.org/) and [wayvnc](https://github.com/any1/wayvnc) for visual debugging via VNC.

To build and use the debug image:

```bash
# Build the debug stage
docker compose build --build-arg BUILDKIT_INLINE_CACHE=1

# Temporarily override the target in compose.override.yml:
#   build:
#     context: .
#     target: debug

# Start with sway instead of gamescope
docker compose run --rm --service-ports steam sway

# In another terminal, start VNC
docker compose exec steam wayvnc 0.0.0.0

# Connect with any VNC client to <host-ip>:5900
```

## Security

The container runs **without** `privileged` mode. It uses the minimum capabilities needed:

| Setting | Reason |
|---------|--------|
| `SYS_NICE` | Gamescope scheduling priority |
| `SYS_PTRACE` | Proton/Wine process introspection (anti-cheat) |
| `seccomp:unconfined` | Gamescope requires some uncommon syscalls |
| `apparmor:unconfined` | Simplifies GPU and audio device access |
| `network_mode: host` | Steam Remote Play needs direct UDP port access |
| `ipc: host` | Shared memory for Gamescope/X11 compositing |

The entrypoint runs as root only to set up UID/GID mapping and start system services, then drops to an unprivileged user (`retro`) via `exec runuser` for the actual Steam process.

## License

MIT
