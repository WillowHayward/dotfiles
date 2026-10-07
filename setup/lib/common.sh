#!/usr/bin/env bash

repo_root=$(cd -- "$setup_dir/.." && pwd)
# shellcheck source=../pins.env
source "$setup_dir/pins.env"
# Termux (Android) has no /etc or root: its $PREFIX stands in for /usr, so the machine
# identity lives in $PREFIX/etc/environment there. Tests set TERMUX_VERSION to simulate it.
is_termux() {
    [[ -n ${TERMUX_VERSION:-} || ${PREFIX:-} == */com.termux/* ]]
}
if is_termux; then
    environment_file=${WHC_ENVIRONMENT_FILE:-${PREFIX:-/data/data/com.termux/files/usr}/etc/environment}
else
    environment_file=${WHC_ENVIRONMENT_FILE:-/etc/environment}
fi
os_release_file=${WHC_OS_RELEASE_FILE:-/etc/os-release}
setup_home=${WHC_SETUP_HOME:-$HOME}
setup_config_home=${WHC_SETUP_CONFIG_HOME:-${XDG_CONFIG_HOME:-$setup_home/.config}}
setup_state_home=${WHC_SETUP_STATE_HOME:-${XDG_STATE_HOME:-$setup_home/.local/state}}
setup_data_home=${WHC_SETUP_DATA_HOME:-${XDG_DATA_HOME:-$setup_home/.local/share}}
declare -A requested_packages=()
apt_updated=false
# apt lists newer than this many seconds are not refreshed again.
apt_fresh_seconds=${WHC_APT_FRESH_SECONDS:-86400}

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
    done <"$environment_file"
    [[ -n $result ]] || return 1
    printf '%s\n' "$result"
}

load_system_identity() {
    WHC_PROFILE=$(read_environment_value WHC_PROFILE) ||
        die "WHC_PROFILE is missing from $environment_file; run 'just setup init-system'."
    WHC_DEVICE=$(read_environment_value WHC_DEVICE) ||
        die "WHC_DEVICE is missing from $environment_file; run 'just setup init-system'."
    case "$WHC_PROFILE" in
    home | work | remote | mobile) ;;
    *) die "invalid WHC_PROFILE '$WHC_PROFILE' in $environment_file" ;;
    esac
    export WHC_PROFILE WHC_DEVICE
}

read_os_release() {
    OS_ID=
    OS_ID_LIKE=
    if is_termux; then
        OS_ID=termux
        return
    fi
    [[ -r "$os_release_file" ]] || die "cannot read $os_release_file"
    while IFS='=' read -r key value; do
        value=${value%\"}
        value=${value#\"}
        case "$key" in
        ID) OS_ID=$value ;;
        ID_LIKE) OS_ID_LIKE=$value ;;
        esac
    done <"$os_release_file"
}

validate_profile_os() {
    read_os_release
    case "$WHC_PROFILE" in
    home)
        [[ $OS_ID == arch ]] ||
            die "profile 'home' requires Arch Linux; detected '${OS_ID:-unknown}'."
        PACKAGE_FAMILY=arch
        ;;
    work | remote)
        if [[ $OS_ID == debian || $OS_ID == ubuntu || " $OS_ID_LIKE " == *" debian "* ]]; then
            PACKAGE_FAMILY=debian
        elif [[ $WHC_PROFILE == remote && $OS_ID == termux ]]; then
            # A phone reached mostly over SSH (a test device) gets the lightweight baseline.
            PACKAGE_FAMILY=termux
        else
            die "profile '$WHC_PROFILE' requires a Debian-family OS; detected '${OS_ID:-unknown}'."
        fi
        ;;
    mobile)
        [[ $OS_ID == termux ]] ||
            die "profile 'mobile' requires Termux; detected '${OS_ID:-unknown}'."
        PACKAGE_FAMILY=termux
        ;;
    esac
    export PACKAGE_FAMILY
}

# Capability tiers: every profile has "core"; "dev" is home, work and mobile; "desktop" is
# home only. The platform (Termux or not) is separate: check PACKAGE_FAMILY or is_termux.
profile_has() {
    case "$1" in
    core) return 0 ;;
    dev) [[ $WHC_PROFILE == home || $WHC_PROFILE == work || $WHC_PROFILE == mobile ]] ;;
    desktop) [[ $WHC_PROFILE == home ]] ;;
    *) die "unknown profile tier '$1'" ;;
    esac
}

# True when version $1 is greater than or equal to version $2 (dotted numbers).
version_at_least() {
    [[ $(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1) == "$2" ]]
}

# Clone a public repository over https regardless of ~/.gitconfig, so a machine
# without a GitHub key can bootstrap. Usage: clone_public URL DIR [COMMIT]; with a
# commit the checkout is pinned to it.
clone_public() {
    local url=$1 dir=$2 ref=${3:-}
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git clone --quiet "$url" "$dir"
    if [[ -n $ref ]]; then
        git -C "$dir" -c advice.detachedHead=false checkout --quiet "$ref"
    fi
}

# Map uname -m onto the architecture names used by release assets: sets ARCH_X86_64
# style suffix in $release_arch (X86_64 or ARM64) or dies.
detect_release_arch() {
    case "$(uname -m)" in
    x86_64) release_arch=X86_64 ;;
    aarch64 | arm64) release_arch=ARM64 ;;
    *) die "no pinned release for architecture '$(uname -m)'." ;;
    esac
}

# Download URL to FILE and refuse it unless its sha256 matches.
download_verified() {
    local url=$1 expected=$2 file=$3
    curl -fL --retry 3 --silent --show-error "$url" -o "$file"
    printf '%s  %s\n' "$expected" "$file" | sha256sum -c - >/dev/null ||
        die "download of $url failed its checksum; refusing to install it."
}

run_as_root() {
    is_termux && die "Termux has no root; this step does not apply here: $*"
    if ((EUID == 0)); then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || die "sudo is required to run: $*"
        sudo "$@"
    fi
}

# True when apt's package lists were refreshed recently (see apt_fresh_seconds).
apt_lists_fresh() {
    local stamp=${WHC_APT_STAMP:-/var/lib/apt/periodic/update-success-stamp} mtime
    [[ -e $stamp ]] || stamp=/var/lib/apt/lists
    mtime=$(stat -c %Y -- "$stamp" 2>/dev/null) || return 1
    (($(date +%s) - mtime < apt_fresh_seconds))
}

# Install packages once per run, skipping any already requested by an earlier task.
install_packages() {
    local package
    local -a missing=()
    for package in "$@"; do
        [[ -n ${requested_packages[$package]:-} ]] || missing+=("$package")
    done
    ((${#missing[@]} > 0)) || return 0
    case "$PACKAGE_FAMILY" in
    arch)
        run_as_root pacman -S --needed --noconfirm "${missing[@]}"
        ;;
    debian)
        if [[ $apt_updated == false ]]; then
            apt_lists_fresh || run_as_root apt-get update
            apt_updated=true
        fi
        run_as_root apt-get install -y "${missing[@]}"
        ;;
    termux)
        # pkg refreshes stale package lists itself, and needs no root.
        pkg install -y "${missing[@]}"
        ;;
    esac
    for package in "${missing[@]}"; do
        requested_packages[$package]=1
    done
}

# Like install_packages, but quietly skips packages the repositories do not offer.
install_optional_packages() {
    local package
    local -a available=()
    for package in "$@"; do
        case "$PACKAGE_FAMILY" in
        arch) pacman -Si "$package" >/dev/null 2>&1 && available+=("$package") ;;
        debian | termux) apt-cache show "$package" >/dev/null 2>&1 && available+=("$package") ;;
        esac
    done
    ((${#available[@]} == 0)) || install_packages "${available[@]}"
}

paths_match() {
    local source=$1 target=$2
    [[ -L $target ]] || return 1
    [[ $(readlink -f -- "$target") == "$(readlink -f -- "$source")" ]]
}

# How link_set treats a target that is not already the right link:
#   strict (default) refuse; relink replace a wrong symlink (never a real file);
#   adopt replace a wrong symlink, and move a real file or directory to a backup first.
link_backup_dir=
backup_target() {
    local target=$1
    [[ -n $link_backup_dir ]] ||
        link_backup_dir=$setup_state_home/whc/backups/$(date +%Y%m%d-%H%M%S)
    mkdir -p -- "$link_backup_dir/$(dirname -- "${target#/}")"
    mv -- "$target" "$link_backup_dir/${target#/}"
    printf 'Moved %s to %s\n' "$target" "$link_backup_dir/${target#/}"
}

check_link() {
    local source=$1 target=$2
    [[ -e $source ]] || die "link source does not exist: $source"
    if [[ -e $target || -L $target ]]; then
        paths_match "$source" "$target" && return 0
        case "${WHC_LINK_MODE:-strict}" in
        relink) [[ -L $target ]] && return 0 ;;
        adopt) return 0 ;;
        esac
        printf 'Refusing to replace %s (use --relink for a wrong symlink, --adopt to back up a real file)\n' "$target" >&2
        return 1
    fi
}

create_link() {
    local source=$1 target=$2
    paths_match "$source" "$target" && return 0
    if [[ -e $target || -L $target ]]; then
        if [[ -L $target ]]; then
            rm -- "$target"
        else
            backup_target "$target"
        fi
    fi
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
