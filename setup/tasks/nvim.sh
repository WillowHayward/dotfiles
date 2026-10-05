#!/usr/bin/env bash

# The config needs Neovim 0.11+ (vim.lsp.config, the nvim-treesitter main branch).
# Debian-family repositories lag behind, so install the pinned official release.
nvim_release_version=${WHC_NVIM_VERSION:-0.12.5}
nvim_minimum_version=0.11

# Release checksums for $nvim_release_version (GitHub release asset digests).
nvim_release_sha256() {
    case "$nvim_release_version:$1" in
        0.12.5:x86_64) printf '%s\n' bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875 ;;
        0.12.5:arm64) printf '%s\n' 1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725 ;;
        *) return 1 ;;
    esac
}

installed_nvim_version() {
    command -v nvim >/dev/null 2>&1 || return 1
    nvim --version | sed -n '1s/^NVIM v\([0-9.]*\).*/\1/p'
}

install_neovim_release() {
    local machine arch expected archive_dir tmp
    machine=$(uname -m)
    case "$machine" in
        x86_64) arch=x86_64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) die "no official Neovim release for architecture '$machine'." ;;
    esac
    expected=$(nvim_release_sha256 "$arch") \
        || die "no pinned checksum for Neovim $nvim_release_version ($arch); update setup/tasks/nvim.sh."
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' RETURN
    curl -fL --retry 3 \
        "https://github.com/neovim/neovim/releases/download/v$nvim_release_version/nvim-linux-$arch.tar.gz" \
        -o "$tmp/nvim.tar.gz"
    printf '%s  %s\n' "$expected" "$tmp/nvim.tar.gz" | sha256sum -c - >/dev/null \
        || die "Neovim download failed its checksum; refusing to install it."
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    archive_dir=$tmp/nvim-linux-$arch
    mkdir -p -- "$setup_home/.local/opt" "$setup_home/.local/bin"
    rm -rf -- "$setup_home/.local/opt/nvim"
    mv -- "$archive_dir" "$setup_home/.local/opt/nvim"
    ln -sfn -- "$setup_home/.local/opt/nvim/bin/nvim" "$setup_home/.local/bin/nvim"
    rm -rf -- "$tmp"
    trap - RETURN
    printf 'Installed Neovim %s to %s\n' "$nvim_release_version" "$setup_home/.local/opt/nvim"
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
