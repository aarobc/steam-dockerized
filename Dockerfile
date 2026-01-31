FROM archlinux:latest

# 1. Enable Multilib
RUN echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

RUN pacman -Syu --noconfirm

RUN pacman -S --noconfirm \
    base-devel \
    steam \
    gamescope \
    vulkan-radeon lib32-vulkan-radeon \
    lib32-libglvnd lib32-gcc-libs \
    pipewire pipewire-pulse wireplumber \
    ttf-liberation wqy-zenhei \
    nss lib32-nss \
    sudo nano htop inetutils neovim

# Install dependencies for Sunshine
RUN pacman -S --noconfirm \
    libva-mesa-driver \
    ffmpeg \
    curl \
    libcap \
    libappindicator \
    libayatana-appindicator \
    libnotify \
    miniupnpc

RUN pacman -S --noconfirm xorg-xeyes

# Install Sunshine from official AppImage (more self-contained)
RUN curl -L -o /usr/local/bin/sunshine.AppImage "https://github.com/LizardByte/Sunshine/releases/download/v2025.924.154138/Sunshine-2025.924.154138-linux.AppImage" && \
    chmod +x /usr/local/bin/sunshine.AppImage && \
    ln -sf /usr/local/bin/sunshine.AppImage /usr/local/bin/sunshine

# Set capabilities for AppImage wrapper
RUN setcap cap_sys_admin+p /usr/local/bin/sunshine.AppImage

# 3. Fix Locales (CRITICAL for Steam UI)
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8

# 4. User Setup
RUN useradd -m -s /bin/bash retro && \
    echo "retro ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 4. Copy our entrypoints
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
WORKDIR /home/retro

ENTRYPOINT ["/entry.sh"]
