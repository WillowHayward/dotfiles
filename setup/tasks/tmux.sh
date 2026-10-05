#!/usr/bin/env bash

task_tmux() {
    install_packages tmux git fzf bat

    if [[ $PACKAGE_FAMILY == debian ]] \
        && command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        mkdir -p -- "$setup_home/.local/bin"
        ln -sfn -- "$(command -v batcat)" "$setup_home/.local/bin/bat"
    fi

    local tpm_dir=$setup_home/.tmux/plugins/tpm
    if [[ -e $tpm_dir ]]; then
        [[ -d $tpm_dir && -d $tpm_dir/.git ]] \
            || die "refusing to replace non-TPM path: $tpm_dir"
    else
        mkdir -p -- "$(dirname -- "$tpm_dir")"
        clone_public https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi

    link_groups tmux
}
