FROM archlinux:latest AS base

RUN echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syu --noconfirm \
    archlinux-keyring \
    steam \
    gamescope \
    vulkan-icd-loader lib32-vulkan-icd-loader \
    lib32-libglvnd lib32-gcc-libs \
    pipewire pipewire-pulse wireplumber \
    ttf-liberation wqy-zenhei \
    nss lib32-nss \
    sudo inetutils neovim \
 && pacman -Scc --noconfirm

# Fix Locales (CRITICAL for Steam UI)
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8

RUN useradd -m -s /bin/bash retro && \
    echo "retro ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
WORKDIR /home/retro

ENTRYPOINT ["/entry.sh"]

# --- AMD GPU ---
FROM base AS amd

RUN pacman -Syu --noconfirm \
    vulkan-radeon lib32-vulkan-radeon \
 && pacman -Scc --noconfirm

# --- NVIDIA GPU ---
FROM base AS nvidia

RUN pacman -Syu --noconfirm \
    nvidia-utils lib32-nvidia-utils \
 && pacman -Scc --noconfirm

# --- Debug: adds sway + wayvnc for visual debugging ---
FROM base AS debug

RUN pacman -Syu --noconfirm \
    sway wayvnc \
 && pacman -Scc --noconfirm
