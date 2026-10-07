#!/usr/bin/env bash

# fnm from its pinned release zip (setup/pins.env), not the unpinned install script.
install_fnm() {
    local release_arch asset expected_var tmp
    detect_release_arch
    [[ $release_arch == X86_64 ]] && asset=fnm-linux.zip || asset=fnm-arm64.zip
    expected_var=FNM_SHA256_$release_arch
    install_packages unzip
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' RETURN
    download_verified "https://github.com/Schniz/fnm/releases/download/v$FNM_VERSION/$asset" \
        "${!expected_var}" "$tmp/fnm.zip"
    unzip -q "$tmp/fnm.zip" -d "$tmp"
    mkdir -p -- "$FNM_DIR"
    install -m 0755 "$tmp/fnm" "$FNM_DIR/fnm"
    rm -rf -- "$tmp"
    trap - RETURN
}

task_node() {
    profile_has dev || die "node is only set up on the home, work and mobile profiles."
    if [[ $PACKAGE_FAMILY == termux ]]; then
        # fnm's Node builds are glibc binaries; Termux packages Node itself, and the
        # tree-sitter package includes the CLI.
        install_packages nodejs-lts tree-sitter
        link_groups node
        node --version
        return
    fi
    install_packages curl
    export FNM_DIR=${FNM_DIR:-$setup_home/.local/share/fnm}
    export PATH="$FNM_DIR:$PATH"
    command -v fnm >/dev/null 2>&1 || install_fnm
    eval "$(fnm env --shell bash)"
    fnm install --lts
    fnm default lts-latest
    fnm use default

    # nvim-treesitter builds its parsers with the tree-sitter CLI (a package on Arch).
    command -v tree-sitter >/dev/null 2>&1 || npm install -g "tree-sitter-cli@$TREE_SITTER_CLI_VERSION"

    link_groups node
    fnm --version
    node --version
    npm --version
}
