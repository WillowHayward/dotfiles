#!/bin/bash
# Install the Walker/Elephant application entry without replacing other settings.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p -- "$applications"
source_file="$repo/walker/applications/whc-projects.desktop"
target="$applications/whc-projects.desktop"
if [[ -e "$target" || -L "$target" ]]; then
    if [[ $(readlink -f -- "$target") != "$source_file" ]]; then
        printf 'Refusing to replace %s\n' "$target" >&2
        exit 1
    fi
else
    ln -s -- "$source_file" "$target"
fi
if command -v update-desktop-database >/dev/null; then
    update-desktop-database "$applications"
fi

# Native Walker provider, available with the # prefix.
menus="${XDG_CONFIG_HOME:-$HOME/.config}/elephant/menus"
mkdir -p -- "$menus"
source_file="$repo/walker/menus/projects.lua"
target="$menus/projects.lua"
if [[ -e "$target" || -L "$target" ]]; then
    if [[ $(readlink -f -- "$target") != "$source_file" ]]; then
        printf 'Refusing to replace %s\n' "$target" >&2
        exit 1
    fi
else
    ln -s -- "$source_file" "$target"
fi
