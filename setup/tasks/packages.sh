#!/usr/bin/env bash

task_packages() {
    local packages
    if [[ $PACKAGE_FAMILY == arch ]]; then
        packages=(base-devel git curl zsh neovim tmux ripgrep fzf lazygit)
    else
        packages=(build-essential git curl zsh neovim tmux ripgrep fzf)
        if apt-cache show lazygit >/dev/null 2>&1; then
            packages+=(lazygit)
        else
            warn "lazygit is unavailable from the configured apt repositories; skipping it."
        fi
    fi
    install_packages "${packages[@]}"
    packages_ready=true
}
