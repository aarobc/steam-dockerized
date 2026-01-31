FROM archlinux:latest

# 1. Enable Multilib
RUN echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# 2. Update & Install Dependencies
# Added: 'locale-gen', 'lib32-libglvnd' (drivers), 'nss' (browser UI)
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    steam \
    gamescope \
    vulkan-radeon lib32-vulkan-radeon \
    lib32-libglvnd lib32-gcc-libs \
    pipewire pipewire-pulse wireplumber \
    ttf-liberation wqy-zenhei \
    nss lib32-nss \
    sudo nano htop inetutils neovim

RUN pacman -S --noconfirm x11vnc

# 3. Fix Locales (CRITICAL for Steam UI)
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8

# 4. User Setup
RUN useradd -m -s /bin/bash retro && \
    echo "retro ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 4. Copy our entrypoint
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

ENTRYPOINT ["/entry.sh"]
