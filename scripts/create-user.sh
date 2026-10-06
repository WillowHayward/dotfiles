#!/usr/bin/env bash
# Create a login user on a fresh server: zsh shell, sudo access and an SSH key.
# Usage (as root): scripts/create-user.sh USER [PUBLIC_KEY_FILE]
# Install zsh first (`just setup packages` or apt-get install zsh).
set -euo pipefail

die() {
    printf 'create-user: %s\n' "$*" >&2
    exit 1
}

((EUID == 0)) || die "run as root."
user=${1:-}
key_file=${2:-}
[[ $user =~ ^[a-z_][a-z0-9_-]*$ ]] || die "usage: $0 USER [PUBLIC_KEY_FILE]"
[[ -z $key_file || -r $key_file ]] || die "cannot read key file: $key_file"
zsh_path=$(command -v zsh) || die "zsh is not installed."

if ! id "$user" >/dev/null 2>&1; then
    useradd --create-home --shell "$zsh_path" "$user"
    passwd "$user"
fi

home=$(getent passwd "$user" | cut -d: -f6)
install -d -m 700 -o "$user" -g "$user" "$home/.ssh"
authorized_keys=$home/.ssh/authorized_keys
install -m 600 -o "$user" -g "$user" -T /dev/null "$authorized_keys.tmp"
[[ ! -f $authorized_keys ]] || cat "$authorized_keys" >"$authorized_keys.tmp"
if [[ -n $key_file ]]; then
    # Append only the keys that are not already authorized.
    new_keys=$(grep -vxFf "$authorized_keys.tmp" "$key_file" || true)
    [[ -z $new_keys ]] || printf '%s\n' "$new_keys" >>"$authorized_keys.tmp"
fi
mv -- "$authorized_keys.tmp" "$authorized_keys"

# Debian-family sudoers group; other distributions use wheel.
if getent group sudo >/dev/null; then
    usermod -aG sudo "$user"
elif getent group wheel >/dev/null; then
    usermod -aG wheel "$user"
fi
printf 'User %s is ready. Next, as that user: git clone <dotfiles> ~/dotfiles && cd ~/dotfiles && just setup init-system && just setup all\n' "$user"
