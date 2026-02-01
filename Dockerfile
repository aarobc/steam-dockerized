FROM archlinux:latest

RUN echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf


RUN pacman -Sy --noconfirm archlinux-keyring
RUN pacman-key --init
RUN pacman-key --populate archlinux

RUN pacman -Sy --noconfirm \
    base-devel \
    steam \
    gamescope \
    vulkan-radeon lib32-vulkan-radeon \
    lib32-libglvnd lib32-gcc-libs \
    pipewire pipewire-pulse wireplumber \
    ttf-liberation wqy-zenhei \
    nss lib32-nss \
    sudo inetutils neovim


RUN pacman -Sy --noconfirm xorg-xeyes mesa-demos wayvnc sway
RUN pacman -Sy --noconfirm dmenu foot swaybg
RUN pacman -Sy --noconfirm evtest
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
