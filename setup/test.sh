#!/usr/bin/env bash
set -euo pipefail

setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

write_environment() {
    local target=$1 profile=$2 device=$3
    printf '# preserved\nUNRELATED="yes"\nWHC_PROFILE="%s"\nWHC_DEVICE="%s"\n' \
        "$profile" "$device" >"$target"
}

write_os_release() {
    local target=$1 id=$2 id_like=${3:-}
    printf 'ID=%s\nID_LIKE="%s"\n' "$id" "$id_like" >"$target"
}

run_setup() {
    local environment=$1 os_release=$2 setup_home=$3 task=$4
    WHC_ENVIRONMENT_FILE=$environment \
        WHC_OS_RELEASE_FILE=$os_release \
        WHC_SETUP_HOME=$setup_home \
        WHC_SETUP_CONFIG_HOME=$setup_home/.config \
        WHC_APT_FRESH_SECONDS=${WHC_APT_FRESH_SECONDS:-0} \
        "$setup_dir/setup.sh" $task # unquoted: a task may carry a flag
}

home_case=$test_root/home
mkdir -p -- "$home_case/user"
write_environment "$home_case/environment" home cowgirl
write_os_release "$home_case/os-release" arch
run_setup "$home_case/environment" "$home_case/os-release" "$home_case/user" links
run_setup "$home_case/environment" "$home_case/os-release" "$home_case/user" links
for link in .zshrc .tmux.session.conf .npmrc .taskrc .config/nvim .config/swayimg .config/hypr \
    .config/walker/config.toml .config/elephant/menus/session.toml .config/mimeapps.list \
    .config/systemd/user/udiskie.service .config/foot/foot.ini .config/mako/config \
    .config/atuin/config.toml .config/direnv/direnvrc .config/lazygit/config.yml .config/gtk-4.0/settings.ini; do
    [[ -L $home_case/user/$link ]] || {
        printf 'Expected home link: %s\n' "$link" >&2
        exit 1
    }
done
[[ $(readlink "$home_case/user/.gitconfig.profile") == */git/profile/home.gitconfig ]]

remote_case=$test_root/remote
mkdir -p -- "$remote_case/user"
write_environment "$remote_case/environment" remote ship
write_os_release "$remote_case/os-release" debian debian
run_setup "$remote_case/environment" "$remote_case/os-release" "$remote_case/user" links
for link in .zshrc .gitconfig .tmux.conf .vimrc .config/atuin/config.toml; do
    [[ -L $remote_case/user/$link ]] || {
        printf 'Expected remote link: %s\n' "$link" >&2
        exit 1
    }
done
for link in .config/nvim .config/swayimg .config/hypr .npmrc .taskrc .tmux.session.conf .config/direnv .config/lazygit .config/foot; do
    [[ ! -e $remote_case/user/$link ]] || {
        printf 'Remote must not link: %s\n' "$link" >&2
        exit 1
    }
done
[[ $(readlink "$remote_case/user/.gitconfig.profile") == */git/profile/remote.gitconfig ]]
for task in manual-lock desktop node python; do
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
    [[ -L $work_case/user/$link ]] || {
        printf 'Expected work link: %s\n' "$link" >&2
        exit 1
    }
done
for link in .config/swayimg .config/hypr; do
    [[ ! -e $work_case/user/$link ]] || {
        printf 'Work must not link: %s\n' "$link" >&2
        exit 1
    }
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
printf 'OTHER=value\n' >"$missing_case/environment"
write_os_release "$missing_case/os-release" arch
if run_setup "$missing_case/environment" "$missing_case/os-release" "$missing_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected missing machine identity to fail.' >&2
    exit 1
fi

identity_case=$test_root/identity
printf '# keep me\nOTHER=value\nWHC_PROFILE="remote"\nWHC_PROFILE="work"\nWHC_DEVICE="old"\n' >"$identity_case"
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
        "$command_name" "$command_name" >"$shim_dir/$command_name"
    chmod +x "$shim_dir/$command_name"
done
printf '#!/usr/bin/env bash\nexit 1\n' >"$shim_dir/apt-cache"
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
: >"$package_case/commands"
WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages 2>"$package_case/stderr"
[[ $(grep -c '^apt-get update' "$package_case/commands") == 1 ]]
grep -q 'apt-get install -y' "$package_case/commands"
grep -q 'build-essential' "$package_case/commands"
grep -q 'lazygit is unavailable' "$package_case/stderr"

write_environment "$package_case/environment" remote ship
: >"$package_case/commands"
WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages 2>"$package_case/stderr"
grep -q ' zsh ' "$package_case/commands"
if grep -qE 'build-essential|neovim|lazygit' "$package_case/commands"; then
    printf '%s\n' 'Remote must not install developer packages.' >&2
    exit 1
fi
[[ ! -s $package_case/stderr ]]

# Fresh apt lists are not refreshed again.
: >"$package_case/commands"
touch "$package_case/apt-stamp"
WHC_APT_STAMP=$package_case/apt-stamp WHC_APT_FRESH_SECONDS=3600 WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages 2>"$package_case/stderr"
! grep -q '^apt-get update' "$package_case/commands"
grep -q '^apt-get install' "$package_case/commands"

(
    # shellcheck source=lib/common.sh
    source "$setup_dir/lib/common.sh"
    version_at_least 0.12.5 0.11
    version_at_least 0.11 0.11
    version_at_least 0.12 0.9.5
    ! version_at_least 0.10.4 0.11
    ! version_at_least 0.9.5 0.11
)

# --relink replaces a wrong symlink; --adopt also backs up a real file. Plain links refuses both.
mode_case=$test_root/mode
mkdir -p -- "$mode_case/user"
write_environment "$mode_case/environment" remote ship
write_os_release "$mode_case/os-release" debian debian
ln -s /nonexistent/elsewhere "$mode_case/user/.zshrc"
printf 'mine\n' >"$mode_case/user/.vimrc"
if run_setup "$mode_case/environment" "$mode_case/os-release" "$mode_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected links to refuse a wrong symlink and a real file.' >&2
    exit 1
fi
if run_setup "$mode_case/environment" "$mode_case/os-release" "$mode_case/user" "links --relink" 2>/dev/null; then
    printf '%s\n' 'Expected --relink to refuse a real file.' >&2
    exit 1
fi
rm "$mode_case/user/.zshrc"
ln -s /nonexistent/elsewhere "$mode_case/user/.zshrc"
rm "$mode_case/user/.vimrc"
run_setup "$mode_case/environment" "$mode_case/os-release" "$mode_case/user" "links --relink" >/dev/null
[[ $(readlink "$mode_case/user/.zshrc") == */shell/.zshrc ]]
rm "$mode_case/user/.vimrc" # a link from the previous step
printf 'mine\n' >"$mode_case/user/.vimrc"
run_setup "$mode_case/environment" "$mode_case/os-release" "$mode_case/user" "links --adopt" >/dev/null
[[ -L $mode_case/user/.vimrc ]]
grep -rqx mine "$mode_case/user/.local/state/whc/backups"

# ssh and bash tasks add their lines once and keep the existing files.
shell_case=$test_root/shellfiles
mkdir -p -- "$shell_case/user/.ssh"
printf 'Host keep\n    HostName example.test\n' >"$shell_case/user/.ssh/config"
printf 'export KEEP=1\n' >"$shell_case/user/.bashrc"
write_environment "$shell_case/environment" remote ship
write_os_release "$shell_case/os-release" debian debian
for _ in 1 2; do
    run_setup "$shell_case/environment" "$shell_case/os-release" "$shell_case/user" ssh
    run_setup "$shell_case/environment" "$shell_case/os-release" "$shell_case/user" bash
done
[[ $(grep -c 'whc-dotfiles config.d' "$shell_case/user/.ssh/config") == 1 ]]
[[ $(grep -c 'whc-dotfiles defaults' "$shell_case/user/.ssh/config") == 1 ]]
[[ $(head -1 "$shell_case/user/.ssh/config") == Include* ]]
grep -qx 'Host keep' "$shell_case/user/.ssh/config"
[[ $(grep -c whc-dotfiles "$shell_case/user/.bashrc") == 1 ]]
grep -qx 'export KEEP=1' "$shell_case/user/.bashrc"
[[ -d $shell_case/user/.ssh/config.d ]]

# greetd rendering: user filled in, uwsm only when installed and not opted out.
(
    # shellcheck source=lib/common.sh
    source "$setup_dir/lib/common.sh"
    # shellcheck source=tasks/manual-lock.sh
    source "$setup_dir/tasks/manual-lock.sh"
    with_uwsm=$(render_greetd_config tester yes)
    without_uwsm=$(render_greetd_config tester no)
    opted_out=$(WHC_NO_UWSM=1 render_greetd_config tester yes)
    grep -q -- '--user tester --cmd uwsm start hyprland.desktop' <<<"$with_uwsm"
    grep -q -- '--user tester --cmd start-hyprland' <<<"$without_uwsm"
    grep -q -- '--cmd start-hyprland' <<<"$opted_out"
    ! grep -q '@' <<<"$with_uwsm"
)

# Device presets are read from an untracked file, ignoring comments and invalid names.
(
    # shellcheck source=lib/common.sh
    source "$setup_dir/lib/common.sh"
    # shellcheck source=tasks/init-system.sh
    source "$setup_dir/tasks/init-system.sh"
    presets=$test_root/devices
    printf '# note\nalpha\n\nbeta # trailing\nba"d\n' >"$presets"
    [[ $(WHC_DEVICES_FILE=$presets device_presets | tr '\n' ' ') == 'alpha beta ' ]]
    [[ -z $(WHC_DEVICES_FILE=$test_root/no-such-file device_presets) ]]
)

printf '%s\n' 'Setup tests passed.'
