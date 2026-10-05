#!/usr/bin/env bash

# Docker Engine and the compose/buildx plugins from Docker's own apt repository (Debian
# and Ubuntu), for servers. The repository key is checked against Docker's published
# fingerprint. Your user is not added to the docker group (that is root-equivalent):
# use sudo, or add yourself deliberately.
docker_key_fingerprint=9DC858229FC7DD38854AE2D88D81803C0EBFCD88

task_docker() {
    [[ $PACKAGE_FAMILY == debian ]] || die "docker is installed from Docker's apt repository (Debian family)."
    [[ $WHC_PROFILE == remote ]] || die "docker setup only runs on the remote profile (home uses pacman, work uses Docker Desktop)."
    install_packages ca-certificates curl gnupg

    local id codename key
    id=$(. "$os_release_file" && printf '%s' "$ID")
    codename=$(. "$os_release_file" && printf '%s' "${VERSION_CODENAME:-}")
    [[ $id == debian || $id == ubuntu ]] || die "Docker publishes repositories for debian and ubuntu, not '$id'."
    [[ -n $codename ]] || die "cannot determine the release codename from $os_release_file."

    key=$(mktemp)
    trap 'rm -f -- "$key"' RETURN
    curl -fsSL "https://download.docker.com/linux/$id/gpg" -o "$key"
    gpg --show-keys --with-colons "$key" | awk -F: '$1 == "fpr" { print $10 }' | grep -qx "$docker_key_fingerprint" ||
        die "Docker's repository key does not match the expected fingerprint; refusing to trust it."
    run_as_root install -d -m 0755 /etc/apt/keyrings
    run_as_root install -m 0644 "$key" /etc/apt/keyrings/docker.asc
    rm -f -- "$key"
    trap - RETURN

    local sources
    sources=$(mktemp)
    printf 'Types: deb\nURIs: https://download.docker.com/linux/%s\nSuites: %s\nComponents: stable\nSigned-By: /etc/apt/keyrings/docker.asc\n' \
        "$id" "$codename" >"$sources"
    run_as_root install -m 0644 "$sources" /etc/apt/sources.list.d/docker.sources
    rm -f -- "$sources"

    run_as_root apt-get update
    apt_updated=true
    install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    docker --version
    printf '%s\n' 'Docker installed. Use sudo docker, or add yourself to the docker group deliberately.'
}
