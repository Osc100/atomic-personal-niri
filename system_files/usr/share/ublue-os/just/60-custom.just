# Set up NUT for the UPS and the Noctalia UPS panel's login
setup-nut:
    sudo /usr/libexec/atomic-niri/setup-nut "$USER"

# Undo setup-nut: stop NUT and put Fedora's /etc/ups back
remove-nut:
    sudo /usr/libexec/atomic-niri/remove-nut "$USER"

# Copy the image's niri config to ~/.config/niri (the old one is backed up)
niri-config:
    #!/usr/bin/bash
    set -euo pipefail
    if [[ -e ~/.config/niri ]]; then
        backup=~/.config/niri.bak.$(date +%Y%m%d%H%M%S)
        mv ~/.config/niri "$backup"
        echo "Backed up the old config to $backup"
    fi
    cp -r /etc/niri ~/.config/niri
    echo "Done. Log out and back in to start on it."

# Copy the image's Noctalia config and settings to your home (the old ones are backed up)
noctalia-config:
    #!/usr/bin/bash
    set -euo pipefail
    stamp=$(date +%Y%m%d%H%M%S)
    if [[ -e ~/.config/noctalia ]]; then
        mv ~/.config/noctalia ~/.config/noctalia.bak.$stamp
        echo "Backed up the old config to ~/.config/noctalia.bak.$stamp"
    fi
    if [[ -e ~/.local/state/noctalia/settings.toml ]]; then
        mv ~/.local/state/noctalia/settings.toml ~/.local/state/noctalia/settings.toml.bak.$stamp
        echo "Backed up the old settings to ~/.local/state/noctalia/settings.toml.bak.$stamp"
    fi
    cp -r /etc/skel/.config/noctalia ~/.config/noctalia
    mkdir -p ~/.local/state/noctalia
    cp /etc/skel/.local/state/noctalia/settings.toml ~/.local/state/noctalia/settings.toml
    echo "Done. Log out and back in to start on it."

# Copy the image's OpenCode config and agent rules to ~/.config/opencode (the old ones are backed up)
opencode-config:
    #!/usr/bin/bash
    set -euo pipefail
    stamp=$(date +%Y%m%d%H%M%S)
    mkdir -p ~/.config/opencode
    for f in opencode.jsonc AGENTS.md; do
        if [[ -e ~/.config/opencode/$f ]]; then
            mv ~/.config/opencode/$f ~/.config/opencode/$f.bak.$stamp
            echo "Backed up the old $f to ~/.config/opencode/$f.bak.$stamp"
        fi
        cp /etc/skel/.config/opencode/$f ~/.config/opencode/$f
    done
    echo "Done. OpenCode reads it on its next start; Devin also needs the devin CLI on your PATH."
