#!/usr/bin/env bash

task_node() {
    install_packages curl
    export FNM_DIR=${FNM_DIR:-$setup_home/.local/share/fnm}
    export PATH="$FNM_DIR:$PATH"
    if ! command -v fnm >/dev/null 2>&1; then
        local installer
        installer=$(mktemp)
        trap 'rm -f -- "$installer"' RETURN
        curl -fsSL https://fnm.vercel.app/install -o "$installer"
        bash "$installer" --skip-shell
        rm -f -- "$installer"
        trap - RETURN
    fi
    eval "$(fnm env --shell bash)"
    fnm install --lts
    fnm default lts-latest
    fnm use default

    local -a node_links=(
        "$repo_root/node/.npmrc|$setup_home/.npmrc"
        "$repo_root/node/.yarnrc.yml|$setup_home/.yarnrc.yml"
    )
    link_set node_links
    fnm --version
    node --version
    npm --version
}
