#!/usr/bin/env bash
set -euo pipefail

setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

write_environment() {
    local target=$1 profile=$2 device=$3
    printf '# preserved\nUNRELATED="yes"\nWHC_PROFILE="%s"\nWHC_DEVICE="%s"\n' \
        "$profile" "$device" > "$target"
}

write_os_release() {
    local target=$1 id=$2 id_like=${3:-}
    printf 'ID=%s\nID_LIKE="%s"\n' "$id" "$id_like" > "$target"
}

run_setup() {
    local environment=$1 os_release=$2 setup_home=$3 task=$4
    WHC_ENVIRONMENT_FILE=$environment \
    WHC_OS_RELEASE_FILE=$os_release \
    WHC_SETUP_HOME=$setup_home \
    WHC_SETUP_CONFIG_HOME=$setup_home/.config \
        "$setup_dir/setup.sh" "$task"
}

home_case=$test_root/home
mkdir -p -- "$home_case/user"
write_environment "$home_case/environment" home cowgirl
write_os_release "$home_case/os-release" arch
run_setup "$home_case/environment" "$home_case/os-release" "$home_case/user" links
run_setup "$home_case/environment" "$home_case/os-release" "$home_case/user" links
for link in .zshrc .tmux.session.conf .npmrc .taskrc .config/nvim .config/swayimg .config/hypr \
    .config/walker/config.toml .config/elephant/menus/session.toml .config/mimeapps.list \
    .config/systemd/user/udiskie.service; do
    [[ -L $home_case/user/$link ]] || { printf 'Expected home link: %s\n' "$link" >&2; exit 1; }
done
[[ $(readlink "$home_case/user/.gitconfig.profile") == */git/profile/home.gitconfig ]]

remote_case=$test_root/remote
mkdir -p -- "$remote_case/user"
write_environment "$remote_case/environment" remote ship
write_os_release "$remote_case/os-release" debian debian
run_setup "$remote_case/environment" "$remote_case/os-release" "$remote_case/user" links
for link in .zshrc .gitconfig .tmux.conf .vimrc; do
    [[ -L $remote_case/user/$link ]] || { printf 'Expected remote link: %s\n' "$link" >&2; exit 1; }
done
for link in .config/nvim .config/swayimg .config/hypr .npmrc .taskrc .tmux.session.conf; do
    [[ ! -e $remote_case/user/$link ]] || { printf 'Remote must not link: %s\n' "$link" >&2; exit 1; }
done
[[ $(readlink "$remote_case/user/.gitconfig.profile") == */git/profile/remote.gitconfig ]]
for task in manual-lock desktop node; do
    if run_setup "$remote_case/environment" "$remote_case/os-release" "$remote_case/user" "$task" 2>/dev/null; then
        printf 'Expected %s to reject the remote profile.\n' "$task" >&2
        exit 1
    fi
done

work_case=$test_root/work
mkdir -p -- "$work_case/user"
write_environment "$work_case/environment" work work
write_os_release "$work_case/os-release" debian debian
run_setup "$work_case/environment" "$work_case/os-release" "$work_case/user" links
for link in .zshrc .tmux.session.conf .npmrc .taskrc .config/nvim; do
    [[ -L $work_case/user/$link ]] || { printf 'Expected work link: %s\n' "$link" >&2; exit 1; }
done
for link in .config/swayimg .config/hypr; do
    [[ ! -e $work_case/user/$link ]] || { printf 'Work must not link: %s\n' "$link" >&2; exit 1; }
done
if run_setup "$work_case/environment" "$work_case/os-release" "$work_case/user" desktop 2>/dev/null; then
    printf '%s\n' 'Expected desktop to reject the work profile.' >&2
    exit 1
fi

legacy_case=$test_root/legacy
mkdir -p -- "$legacy_case/user"
write_environment "$legacy_case/environment" remote ship
write_os_release "$legacy_case/os-release" debian debian
ln -s "$(cd "$setup_dir/.." && pwd)/shell/.zsh_plugins.txt" "$legacy_case/user/.zsh_plugins.txt"
run_setup "$legacy_case/environment" "$legacy_case/os-release" "$legacy_case/user" links
[[ ! -e $legacy_case/user/.zsh_plugins.txt && ! -L $legacy_case/user/.zsh_plugins.txt ]]

conflict_case=$test_root/conflict
mkdir -p -- "$conflict_case/user"
write_environment "$conflict_case/environment" home bessie
write_os_release "$conflict_case/os-release" arch
touch "$conflict_case/user/.zshrc"
if run_setup "$conflict_case/environment" "$conflict_case/os-release" "$conflict_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected link conflict to fail.' >&2
    exit 1
fi
[[ ! -e $conflict_case/user/.gitconfig ]]

mismatch_case=$test_root/mismatch
mkdir -p -- "$mismatch_case/user"
write_environment "$mismatch_case/environment" work work
write_os_release "$mismatch_case/os-release" arch
if run_setup "$mismatch_case/environment" "$mismatch_case/os-release" "$mismatch_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected profile/OS mismatch to fail.' >&2
    exit 1
fi

missing_case=$test_root/missing
mkdir -p -- "$missing_case/user"
printf 'OTHER=value\n' > "$missing_case/environment"
write_os_release "$missing_case/os-release" arch
if run_setup "$missing_case/environment" "$missing_case/os-release" "$missing_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected missing machine identity to fail.' >&2
    exit 1
fi

identity_case=$test_root/identity
printf '# keep me\nOTHER=value\nWHC_PROFILE="remote"\nWHC_PROFILE="work"\nWHC_DEVICE="old"\n' > "$identity_case"
(
    export WHC_ENVIRONMENT_FILE=$identity_case
    # shellcheck source=lib/common.sh
    source "$setup_dir/lib/common.sh"
    # shellcheck source=tasks/init-system.sh
    source "$setup_dir/tasks/init-system.sh"
    write_system_identity home 'test device'
)
grep -qx '# keep me' "$identity_case"
grep -qx 'OTHER=value' "$identity_case"
[[ $(grep -c '^WHC_PROFILE=' "$identity_case") == 1 ]]
grep -qx 'WHC_PROFILE="home"' "$identity_case"
grep -qx 'WHC_DEVICE="test device"' "$identity_case"

shim_dir=$test_root/shims
mkdir -p -- "$shim_dir"
for command_name in sudo pacman apt-get; do
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s $*" >> "$WHC_TEST_LOG"\nif [[ "%s" == sudo ]]; then exec "$@"; fi\n' \
        "$command_name" "$command_name" > "$shim_dir/$command_name"
    chmod +x "$shim_dir/$command_name"
done
printf '#!/usr/bin/env bash\nexit 1\n' > "$shim_dir/apt-cache"
chmod +x "$shim_dir/apt-cache"

package_case=$test_root/packages
mkdir -p -- "$package_case/user"
write_environment "$package_case/environment" home cowgirl
write_os_release "$package_case/os-release" arch
WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages
grep -q 'pacman -S --needed --noconfirm' "$package_case/commands"

grep -q 'neovim' "$package_case/commands"
[[ $(grep -c '^pacman' "$package_case/commands") == 1 ]]

write_environment "$package_case/environment" work work
write_os_release "$package_case/os-release" ubuntu debian
: > "$package_case/commands"
WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages 2> "$package_case/stderr"
[[ $(grep -c '^apt-get update' "$package_case/commands") == 1 ]]
grep -q 'apt-get install -y' "$package_case/commands"
grep -q 'build-essential' "$package_case/commands"
grep -q 'lazygit is unavailable' "$package_case/stderr"

write_environment "$package_case/environment" remote ship
: > "$package_case/commands"
WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages 2> "$package_case/stderr"
grep -q ' zsh ' "$package_case/commands"
if grep -qE 'build-essential|neovim|lazygit' "$package_case/commands"; then
    printf '%s\n' 'Remote must not install developer packages.' >&2
    exit 1
fi
[[ ! -s $package_case/stderr ]]

(
    # shellcheck source=lib/common.sh
    source "$setup_dir/lib/common.sh"
    version_at_least 0.12.5 0.11
    version_at_least 0.11 0.11
    version_at_least 0.12 0.9.5
    ! version_at_least 0.10.4 0.11
    ! version_at_least 0.9.5 0.11
)

printf '%s\n' 'Setup tests passed.'
