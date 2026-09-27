#!/usr/bin/env bash
# Run with sudo (or pkexec) after linking ~/.config/hypr to dotfiles/hypr.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $EUID -ne 0 ]]; then
    echo "Run this script with sudo or pkexec." >&2
    exit 1
fi
pacman -S --needed --noconfirm greetd-tuigreet hyprlock hypridle
install -d /etc/systemd/logind.conf.d
ln -sfn "$repo/systemd/logind.conf" /etc/systemd/logind.conf.d/60-manual-power.conf
install -d /etc/systemd/system/systemd-logind.service.d
ln -sfn "$repo/systemd/logind-dotfiles.conf" /etc/systemd/system/systemd-logind.service.d/60-dotfiles.conf
systemctl daemon-reload
# The sandbox change takes effect on reboot; do not disrupt active sessions.

# Do not restart greetd: it would terminate the active desktop session.
