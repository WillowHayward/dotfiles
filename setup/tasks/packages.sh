#!/usr/bin/env bash

# Package names per tier. Core is installed on every profile and dev adds the
# developer toolchain (home and work). The desktop tier (the Hyprland session,
# home only) is installed by task_desktop.
tier_packages() {
    case "$PACKAGE_FAMILY:$1" in
    arch:core)
        printf '%s\n' git curl zsh tmux ripgrep fzf bat vim less openssh git-delta fd \
            htop ncdu rsync jq unzip tree man-db eza zoxide atuin
        ;;
    arch:dev)
        printf '%s\n' base-devel neovim lazygit github-cli python tree-sitter-cli direnv \
            shellcheck shfmt gitleaks task stylua yamllint
        ;;
    arch:desktop)
        printf '%s\n' hyprland hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland \
            xdg-desktop-portal-gtk uwsm foot thunar firefox udiskie mako grim flameshot swayimg \
            wl-clipboard pipewire wireplumber playerctl brightnessctl ddcutil libnotify \
            noto-fonts noto-fonts-emoji adwaita-fonts ttf-nerd-fonts-symbols
        ;;
    debian:core)
        printf '%s\n' git curl ca-certificates zsh tmux ripgrep fzf bat vim less openssh-client \
            git-delta fd-find htop ncdu rsync jq unzip tree man-db
        ;;
    debian:dev)
        printf '%s\n' build-essential gh python3 python3-pip python3-venv direnv shfmt \
            taskwarrior yamllint
        ;;
    *) return 0 ;; # Tiers without packages on this distribution (e.g. debian desktop).
    esac
}

# Nice-to-haves that older releases may not package; each is installed only when the
# repositories offer it (the shell guards every use with `command -v`).
tier_optional_packages() {
    case "$PACKAGE_FAMILY:$1" in
    debian:core) printf '%s\n' eza zoxide atuin ;;
    debian:dev) printf '%s\n' shellcheck gitleaks ;;
    esac
}

# Every package name in the profile's manifest, one per line, tagged with its tier.
manifest_packages() {
    local tier name
    for tier in core dev; do
        profile_has "$tier" || continue
        while read -r name; do printf '%s\t%s\n' "$name" "$tier"; done < <(tier_packages "$tier")
        while read -r name; do printf '%s\t%s (optional)\n' "$name" "$tier"; done < <(tier_optional_packages "$tier")
    done
    if profile_has desktop; then
        while read -r name; do printf '%s\tdesktop\n' "$name"; done < <(tier_packages desktop)
    fi
}

packages_diff() {
    local manifest installed
    manifest=$(manifest_packages | cut -f1 | sort -u)
    case "$PACKAGE_FAMILY" in
    arch) installed=$(pacman -Qqe | sort -u) ;;
    debian) installed=$(apt-mark showmanual | sort -u) ;;
    esac
    printf 'Installed explicitly but not in the manifest (add to tier_packages, or ignore):\n'
    comm -13 <(printf '%s\n' "$manifest") <(printf '%s\n' "$installed")
}

task_packages() {
    case "${WHC_PACKAGES_MODE:-}" in
    list)
        manifest_packages | sort
        return
        ;;
    diff)
        packages_diff
        return
        ;;
    esac
    local tier
    local -a packages=() optional=()
    for tier in core dev; do
        profile_has "$tier" || continue
        mapfile -t -O "${#packages[@]}" packages < <(tier_packages "$tier")
        mapfile -t -O "${#optional[@]}" optional < <(tier_optional_packages "$tier")
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
    install_optional_packages "${optional[@]}"
    if [[ $PACKAGE_FAMILY == debian ]]; then
        # Debian renames these binaries; the tools and muscle memory expect the upstream names.
        shim_command fdfind fd
        shim_command batcat bat
    fi
}

# Link $2 into ~/.local/bin as an alias for the installed command $1 (when $2 is missing).
shim_command() {
    local installed=$1 wanted=$2
    command -v "$installed" >/dev/null 2>&1 || return 0
    command -v "$wanted" >/dev/null 2>&1 && return 0
    mkdir -p -- "$setup_home/.local/bin"
    ln -sfn -- "$(command -v "$installed")" "$setup_home/.local/bin/$wanted"
}
