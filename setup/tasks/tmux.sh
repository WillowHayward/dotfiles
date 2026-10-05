#!/usr/bin/env bash

task_tmux() {
    install_packages tmux git

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
