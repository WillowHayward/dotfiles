#!/usr/bin/env bash

task_nvim() {
    install_packages neovim ripgrep git
    local -a nvim_links=("$repo_root/nvim|$setup_config_home/nvim")
    link_set nvim_links
}
