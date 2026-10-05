#!/usr/bin/env bash

# The config needs Neovim 0.11+ (vim.lsp.config, the nvim-treesitter main branch).
# Debian-family repositories lag behind, so install the pinned official release
# (version and checksums: setup/pins.env).
nvim_minimum_version=0.11

installed_nvim_version() {
    command -v nvim >/dev/null 2>&1 || return 1
    nvim --version | sed -n '1s/^NVIM v\([0-9.]*\).*/\1/p'
}

install_neovim_release() {
    local release_arch asset_arch expected_var tmp version=${WHC_NVIM_VERSION:-$NVIM_VERSION}
    detect_release_arch
    asset_arch=${release_arch,,}
    expected_var=NVIM_SHA256_$release_arch
    [[ $version == "$NVIM_VERSION" ]] ||
        die "WHC_NVIM_VERSION=$version has no pinned checksum; update setup/pins.env instead."
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' RETURN
    download_verified \
        "https://github.com/neovim/neovim/releases/download/v$version/nvim-linux-$asset_arch.tar.gz" \
        "${!expected_var}" "$tmp/nvim.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    mkdir -p -- "$setup_home/.local/opt" "$setup_home/.local/bin"
    rm -rf -- "$setup_home/.local/opt/nvim"
    mv -- "$tmp/nvim-linux-$asset_arch" "$setup_home/.local/opt/nvim"
    ln -sfn -- "$setup_home/.local/opt/nvim/bin/nvim" "$setup_home/.local/bin/nvim"
    rm -rf -- "$tmp"
    trap - RETURN
    printf 'Installed Neovim %s to %s\n' "$version" "$setup_home/.local/opt/nvim"
}

task_nvim() {
    profile_has dev || warn "the remote profile uses vim; this Neovim config is built for home and work."
    install_packages ripgrep git curl
    if [[ $PACKAGE_FAMILY == arch ]]; then
        install_packages neovim
    else
        local current
        current=$(installed_nvim_version || true)
        if [[ -z $current ]] || ! version_at_least "$current" "$nvim_minimum_version"; then
            install_neovim_release
        fi
    fi
    link_groups nvim
}
