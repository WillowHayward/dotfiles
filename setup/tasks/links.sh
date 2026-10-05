#!/usr/bin/env bash

common_links() {
    LINKS=(
        "$repo_root/shell/.zshrc|$setup_home/.zshrc"
        "$repo_root/shell/.zsh_plugins.txt|$setup_home/.zsh_plugins.txt"
        "$repo_root/git/.gitconfig|$setup_home/.gitconfig"
        "$repo_root/git/.gitignore.global|$setup_home/.gitignore.global"
        "$repo_root/shell/.tmux.conf|$setup_home/.tmux.conf"
        "$repo_root/nvim|$setup_config_home/nvim"
        "$repo_root/node/.npmrc|$setup_home/.npmrc"
        "$repo_root/node/.yarnrc.yml|$setup_home/.yarnrc.yml"
        "$repo_root/vim/.vimrc|$setup_home/.vimrc"
        "$repo_root/taskwarrior/.taskrc|$setup_home/.taskrc"
    )
    if [[ $WHC_PROFILE == home ]]; then
        LINKS+=("$repo_root/swayimg|$setup_config_home/swayimg")
    fi
}

task_links() {
    local -a LINKS
    common_links
    link_set LINKS
}
