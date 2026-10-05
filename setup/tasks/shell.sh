#!/usr/bin/env bash

task_shell() {
    install_packages zsh git curl

    local antidote_dir=${ANTIDOTE_DIR:-${ZDOTDIR:-$setup_home}/.antidote}
    if [[ -e $antidote_dir ]]; then
        [[ -d $antidote_dir && -d $antidote_dir/.git ]] \
            || die "refusing to replace non-Antidote path: $antidote_dir"
    else
        mkdir -p -- "$(dirname -- "$antidote_dir")"
        git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
    fi

    local -a shell_links=(
        "$repo_root/shell/.zshrc|$setup_home/.zshrc"
        "$repo_root/shell/.zsh_plugins.txt|$setup_home/.zsh_plugins.txt"
    )
    link_set shell_links

    local zsh_path login_shell current_user
    zsh_path=$(command -v zsh) || die "zsh was not found after installation."
    current_user=$(id -un)
    login_shell=$(getent passwd "$current_user" | cut -d: -f7)
    if [[ $login_shell != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
    fi
}
