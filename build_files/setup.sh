#!/bin/bash
# Runs after system_files is copied in.

set -ouex pipefail

# Fedora's greetd runs the greeter as "greetd", not "greeter".
GREETER_USER=greetd /usr/share/noctalia-greeter/setup_greeter_system.sh

sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd

# Only accept this image signed with our key, as ublue's policy does for
# ghcr.io/ublue-os. Without this, ghcr.io/osc100 falls under the policy's
# accept-anything default.
jq '.transports.docker["ghcr.io/osc100/atomic-personal-niri"] = [{
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/atomic-personal-niri.pub",
    "signedIdentity": { "type": "matchRepository" }
}]' /etc/containers/policy.json >/tmp/policy.json
cp /tmp/policy.json /etc/containers/policy.json

systemctl enable podman.socket
systemctl enable greetd.service
systemctl enable tailscaled.service
systemctl enable tuned.service
systemctl enable tuned-ppd.service
systemctl enable atomic-niri-flatpak-preinstall.service
systemctl set-default graphical.target

# For every user: Devin and subagent steering for OpenCode, on 127.0.0.1:47821.
systemctl --global enable claude-devin-serve.service
