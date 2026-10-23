#!/usr/bin/env bash

# Every profile gets the core tasks; developer tooling and the desktop are
# added by the profile's tiers (see profile_has).
task_all() {
    task_packages
    link_stacks
    # ~/.taskrc includes this untracked file (sync settings); Taskwarrior refuses a missing include.
    if profile_has dev && [[ ! -e $setup_home/.taskrc.local ]]; then
        : >"$setup_home/.taskrc.local"
    fi
    # Commit hooks (secret scan, checks) apply when the repo is a checkout we manage.
    if [[ -d $repo_root/.githooks && $setup_home == "$HOME" ]]; then
        git -C "$repo_root" config core.hooksPath .githooks
    fi
    task_shell
    task_tmux
    task_ssh
    task_bash
    if profile_has dev; then
        task_nvim
        task_node
        task_python
    fi
    if [[ $WHC_PROFILE == remote && $PACKAGE_FAMILY != termux ]]; then
        task_docker
    fi
    if [[ $PACKAGE_FAMILY == termux ]]; then
        task_termux
    fi
    if profile_has desktop; then
        task_desktop
    fi
}
