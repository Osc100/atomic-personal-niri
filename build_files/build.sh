#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

### Repositories

# Terra, for what Fedora doesn't package. terra-release carries the signing
# key, so only this first install skips the check.
dnf5 -y install --nogpgcheck \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

dnf5 -y copr enable yalter/niri-git

### Desktop

# The COPR's version (0.0.git.N) sorts below Fedora's niri 26.04, so without
# --from-repo dnf picks Fedora's.
dnf5 -y install --from-repo=copr:copr.fedorainfracloud.org:yalter:niri-git niri
dnf5 -y install --from-repo=terra noctalia-greeter gpu-screen-recorder satty

dnf5 -y install \
    noctalia \
    xwayland-satellite \
    greetd \
    greetd-selinux \
    accountsservice \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    oo7-daemon \
    oo7-portal \
    pam_oo7 \
    wl-clipboard \
    brightnessctl \
    ddcutil \
    nut \
    nut-client

# oo7 replaces gnome-keyring, as on Fedora 45. niri and noctalia pull
# gnome-keyring in as a weak dependency.
dnf5 -y remove gnome-keyring gnome-keyring-pam

# Fedora's greetd runs the greeter as "greetd", not "greeter".
GREETER_USER=greetd /usr/share/noctalia-greeter/setup_greeter_system.sh

### Shell

dnf5 -y install fish fastfetch
dnf5 -y install --from-repo=terra starship

sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd

### Apps and tools

dnf5 -y install \
    kitty \
    alacritty \
    nautilus \
    jetbrains-mono-fonts-all \
    google-noto-sans-fonts \
    neovim \
    tree-sitter-cli \
    ripgrep \
    gh \
    lsd \
    btop \
    tailscale
dnf5 -y install --from-repo=terra zellij mise

# Without the rpm-ostree plugin, so it only handles Flatpaks.
dnf5 -y install --exclude=gnome-software-rpm-ostree gnome-software

### Development

# Bevy needs a C compiler and these headers to build.
dnf5 -y install \
    gcc \
    gcc-c++ \
    pkgconf-pkg-config \
    alsa-lib-devel \
    systemd-devel \
    wayland-devel \
    libxkbcommon-devel \
    vulkan-loader-devel \
    squashfs-tools \
    podman-compose \
    just

### Removed from the base

# boto3 is only there because sos recommends it. Browsers come from Flathub.
dnf5 -y remove \
    nvidia-gpu-firmware \
    firefox \
    firefox-langpacks \
    python3-boto3 \
    python3-botocore \
    python3-s3transfer \
    'ibus*' \
    anthy-unicode \
    libchewing \
    libhangul \
    libpinyin \
    libpinyin-data \
    m17n-db \
    m17n-lib

### Cleanup

dnf5 -y copr disable yalter/niri-git
dnf5 config-manager setopt 'terra*.enabled=0'

### Services

systemctl enable podman.socket
systemctl enable greetd.service
systemctl enable tailscaled.service
systemctl enable atomic-niri-flatpak-preinstall.service
systemctl set-default graphical.target
