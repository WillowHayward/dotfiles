#!/usr/bin/env bash

# Source the repo's tiny bashrc from ~/.bashrc without replacing the distribution's file.
task_bash() {
    local bashrc=$setup_home/.bashrc line
    line="[ -r \"$repo_root/shell/.bashrc\" ] && . \"$repo_root/shell/.bashrc\" # whc-dotfiles"
    [[ -e $bashrc ]] || : >"$bashrc"
    grep -qF '# whc-dotfiles' "$bashrc" || printf '\n%s\n' "$line" >>"$bashrc"
}
