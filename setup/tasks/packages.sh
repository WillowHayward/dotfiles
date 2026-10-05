#!/usr/bin/env bash

# Package names per tier. Core is installed on every profile and dev adds the
# developer toolchain (home and work). The desktop tier (the Hyprland session,
# home only) is installed by task_desktop.
tier_packages() {
    case "$PACKAGE_FAMILY:$1" in
        arch:core) printf '%s\n' git curl zsh tmux ripgrep fzf vim less openssh ;;
        arch:dev) printf '%s\n' base-devel neovim lazygit fd jq unzip python tree-sitter-cli ;;
        arch:desktop)
            printf '%s\n' hyprland hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland \
                foot thunar firefox udiskie mako grim flameshot swayimg wl-clipboard \
                pipewire wireplumber playerctl brightnessctl ddcutil libnotify \
                noto-fonts noto-fonts-emoji adwaita-fonts ttf-nerd-fonts-symbols
            ;;
        debian:core) printf '%s\n' git curl ca-certificates zsh tmux ripgrep fzf vim less openssh-client ;;
        debian:dev) printf '%s\n' build-essential fd-find jq unzip python3 python3-pip python3-venv ;;
        *) return 0 ;; # Tiers without packages on this distribution (e.g. debian desktop).
    esac
}

task_packages() {
    local tier
    local -a packages=()
    for tier in core dev; do
        profile_has "$tier" || continue
        mapfile -t -O "${#packages[@]}" packages < <(tier_packages "$tier")
    done
    if [[ $PACKAGE_FAMILY == debian ]] && profile_has dev; then
        # Neovim comes from task_nvim: Debian's packaged version is too old for this config.
        if apt-cache show lazygit >/dev/null 2>&1; then
            packages+=(lazygit)
        else
            warn "lazygit is unavailable from the configured apt repositories; skipping it."
        fi
    fi
    install_packages "${packages[@]}"
}
