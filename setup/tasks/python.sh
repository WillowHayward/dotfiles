#!/usr/bin/env bash

# uv manages Python tools and virtual environments (replaces ad-hoc pip/pipx use).
# Arch ships it; elsewhere install the pinned release (setup/pins.env).
install_uv_release() {
    local release_arch triple expected_var tmp
    detect_release_arch
    [[ $release_arch == X86_64 ]] && triple=x86_64-unknown-linux-gnu || triple=aarch64-unknown-linux-gnu
    expected_var=UV_SHA256_$release_arch
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' RETURN
    download_verified "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-$triple.tar.gz" \
        "${!expected_var}" "$tmp/uv.tar.gz"
    tar -xzf "$tmp/uv.tar.gz" -C "$tmp"
    mkdir -p -- "$setup_home/.local/bin"
    install -m 0755 "$tmp/uv-$triple/uv" "$tmp/uv-$triple/uvx" "$setup_home/.local/bin/"
    rm -rf -- "$tmp"
    trap - RETURN
    printf 'Installed uv %s to %s\n' "$UV_VERSION" "$setup_home/.local/bin"
}

task_python() {
    profile_has dev || die "uv is only set up on the home, work and mobile profiles."
    if [[ $PACKAGE_FAMILY == arch || $PACKAGE_FAMILY == termux ]]; then
        install_packages uv
    else
        install_packages curl
        command -v uv >/dev/null 2>&1 || install_uv_release
    fi
}
