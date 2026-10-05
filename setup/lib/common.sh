#!/usr/bin/env bash

repo_root=$(cd -- "$setup_dir/.." && pwd)
environment_file=${WHC_ENVIRONMENT_FILE:-/etc/environment}
os_release_file=${WHC_OS_RELEASE_FILE:-/etc/os-release}
setup_home=${WHC_SETUP_HOME:-$HOME}
setup_config_home=${WHC_SETUP_CONFIG_HOME:-${XDG_CONFIG_HOME:-$setup_home/.config}}
declare -A requested_packages=()
apt_updated=false

die() {
    printf 'setup: %s\n' "$*" >&2
    exit 1
}

warn() {
    printf 'setup: warning: %s\n' "$*" >&2
}

read_environment_value() {
    local wanted=$1 key value result=
    [[ -r "$environment_file" ]] || return 1
    while IFS='=' read -r key value; do
        key=${key//[[:space:]]/}
        [[ $key == "$wanted" ]] || continue
        value=${value#"${value%%[![:space:]]*}"}
        value=${value%"${value##*[![:space:]]}"}
        if [[ $value == \"*\" && $value == *\" ]]; then
            value=${value:1:${#value}-2}
        elif [[ $value == \'*\' && $value == *\' ]]; then
            value=${value:1:${#value}-2}
        fi
        result=$value
    done < "$environment_file"
    [[ -n $result ]] || return 1
    printf '%s\n' "$result"
}

load_system_identity() {
    WHC_PROFILE=$(read_environment_value WHC_PROFILE) \
        || die "WHC_PROFILE is missing from $environment_file; run 'just setup init-system'."
    WHC_DEVICE=$(read_environment_value WHC_DEVICE) \
        || die "WHC_DEVICE is missing from $environment_file; run 'just setup init-system'."
    case "$WHC_PROFILE" in
        home|work|remote) ;;
        *) die "invalid WHC_PROFILE '$WHC_PROFILE' in $environment_file" ;;
    esac
    export WHC_PROFILE WHC_DEVICE
}

read_os_release() {
    [[ -r "$os_release_file" ]] || die "cannot read $os_release_file"
    OS_ID=
    OS_ID_LIKE=
    while IFS='=' read -r key value; do
        value=${value%\"}
        value=${value#\"}
        case "$key" in
            ID) OS_ID=$value ;;
            ID_LIKE) OS_ID_LIKE=$value ;;
        esac
    done < "$os_release_file"
}

validate_profile_os() {
    read_os_release
    case "$WHC_PROFILE" in
        home)
            [[ $OS_ID == arch ]] \
                || die "profile 'home' requires Arch Linux; detected '${OS_ID:-unknown}'."
            PACKAGE_FAMILY=arch
            ;;
        work|remote)
            if [[ $OS_ID == debian || $OS_ID == ubuntu || " $OS_ID_LIKE " == *" debian "* ]]; then
                PACKAGE_FAMILY=debian
            else
                die "profile '$WHC_PROFILE' requires a Debian-family OS; detected '${OS_ID:-unknown}'."
            fi
            ;;
    esac
    export PACKAGE_FAMILY
}

# Capability tiers: every profile has "core"; "dev" is home and work; "desktop" is home only.
profile_has() {
    case "$1" in
        core) return 0 ;;
        dev) [[ $WHC_PROFILE == home || $WHC_PROFILE == work ]] ;;
        desktop) [[ $WHC_PROFILE == home ]] ;;
        *) die "unknown profile tier '$1'" ;;
    esac
}

# True when version $1 is greater than or equal to version $2 (dotted numbers).
version_at_least() {
    [[ $(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1) == "$2" ]]
}

run_as_root() {
    if (( EUID == 0 )); then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || die "sudo is required to run: $*"
        sudo "$@"
    fi
}

# Install packages once per run, skipping any already requested by an earlier task.
install_packages() {
    local package
    local -a missing=()
    for package in "$@"; do
        [[ -n ${requested_packages[$package]:-} ]] || missing+=("$package")
    done
    (( ${#missing[@]} > 0 )) || return 0
    case "$PACKAGE_FAMILY" in
        arch)
            run_as_root pacman -S --needed --noconfirm "${missing[@]}"
            ;;
        debian)
            if [[ $apt_updated == false ]]; then
                run_as_root apt-get update
                apt_updated=true
            fi
            run_as_root apt-get install -y "${missing[@]}"
            ;;
    esac
    for package in "${missing[@]}"; do
        requested_packages[$package]=1
    done
}

paths_match() {
    local source=$1 target=$2
    [[ -L $target ]] || return 1
    [[ $(readlink -f -- "$target") == "$(readlink -f -- "$source")" ]]
}

check_link() {
    local source=$1 target=$2
    [[ -e $source ]] || die "link source does not exist: $source"
    if [[ -e $target || -L $target ]]; then
        paths_match "$source" "$target" \
            || { printf 'Refusing to replace %s\n' "$target" >&2; return 1; }
    fi
}

create_link() {
    local source=$1 target=$2
    paths_match "$source" "$target" && return 0
    mkdir -p -- "$(dirname -- "$target")"
    ln -s -- "$source" "$target"
    printf 'Linked %s -> %s\n' "$target" "$source"
}

link_set() {
    local -n requested_links=$1
    local item source target failed=false
    for item in "${requested_links[@]}"; do
        source=${item%%|*}
        target=${item#*|}
        check_link "$source" "$target" || failed=true
    done
    [[ $failed == false ]] || die "resolve the link conflicts above and run setup again."
    for item in "${requested_links[@]}"; do
        source=${item%%|*}
        target=${item#*|}
        create_link "$source" "$target"
    done
}
