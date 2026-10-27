#!/bin/bash

set -ouex pipefail

### Repositories

# Terra, for what Fedora doesn't package. dnf expands $releasever in the repo
# URL but not in --setopt, hence rpm -E for the key's.
fedora="$(rpm -E %fedora)"
dnf5 -y install \
    --repofrompath "terra,https://repos.fyralabs.com/terra${fedora}" \
    --setopt=terra.gpgcheck=1 \
    --setopt="terra.gpgkey=https://repos.fyralabs.com/terra${fedora}/key.asc" \
    terra-release

dnf5 -y copr enable yalter/niri-git

### Desktop

# The COPR's version (0.0.git.N) sorts below Fedora's niri 26.04, so without
# --from-repo dnf picks Fedora's. Of what niri recommends, Noctalia replaces
# waybar, fuzzel, mako, swaybg, swayidle and swaylock; Ghostty replaces alacritty
# and oo7 gnome-keyring.
dnf5 -y install --from-repo=copr:copr.fedorainfracloud.org:yalter:niri-git \
    --exclude=alacritty,fuzzel,mako,swaybg,swayidle,swaylock,waybar \
    --exclude='gnome-keyring*' niri
dnf5 -y install --from-repo=terra noctalia-greeter gpu-screen-recorder

# Noctalia 5.3.0, the version the config was written with, is still in
# updates-testing for Fedora 45, and 5.2.1 refuses its newer settings. It
# recommends power-profiles-daemon, which tlp-pd also provides, and tlp
# conflicts with the tuned below.
dnf5 -y install --enablerepo=updates-testing --exclude='gnome-keyring* power-profiles-daemon tlp tlp-pd' noctalia

# tuned-ppd serves power-profiles-daemon's D-Bus API
# (org.freedesktop.UPower.PowerProfiles) on top of tuned, which is what
# Noctalia's power profile widget talks to.
dnf5 -y install \
    tuned \
    tuned-ppd

dnf5 -y install \
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

### Shell

dnf5 -y install fish fastfetch
dnf5 -y install --from-repo=terra starship

### Apps and tools

# tree-sitter-cli recommends Node.js (about 100 MB with npm and its docs), which
# it only needs to generate a parser from a grammar. Node comes from mise.
dnf5 -y install --exclude='nodejs*' \
    kitty \
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
dnf5 -y install --from-repo=terra ghostty zellij mise zed

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
