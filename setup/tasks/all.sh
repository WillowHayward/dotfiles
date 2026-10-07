#!/usr/bin/env bash

# Every profile gets the core tasks; developer tooling and the desktop are
# added by the profile's tiers (see profile_has).
task_all() {
    task_packages
    task_links
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
