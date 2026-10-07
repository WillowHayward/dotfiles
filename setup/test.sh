#!/usr/bin/env bash
set -euo pipefail

setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
# Sandbox HOME and the XDG directories: a task that misses a WHC_SETUP_* override must not touch the real home.
export HOME=$test_root/sandbox-home
mkdir -p -- "$HOME"
unset XDG_CONFIG_HOME XDG_STATE_HOME XDG_DATA_HOME XDG_CACHE_HOME

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
    local -a arguments
    read -ra arguments <<<"$task" # a task may carry a flag, e.g. "links --adopt"
    WHC_ENVIRONMENT_FILE=$environment \
        WHC_OS_RELEASE_FILE=$os_release \
        WHC_SETUP_HOME=$setup_home \
        WHC_SETUP_CONFIG_HOME=$setup_home/.config \
        WHC_SETUP_STATE_HOME=$setup_home/.local/state \
        WHC_SETUP_DATA_HOME=$setup_home/.local/share \
        WHC_APT_FRESH_SECONDS=${WHC_APT_FRESH_SECONDS:-0} \
        "$setup_dir/setup.sh" "${arguments[@]}"
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
write_environment "$remote_case/environment" remote testbox
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

# Termux (TERMUX_VERSION simulates it): mobile gets the developer tooling, a remote test
# phone the baseline, and both the Termux settings. Neither profile fits the other platform.
mobile_case=$test_root/mobile
mkdir -p -- "$mobile_case/user"
write_environment "$mobile_case/environment" mobile phone
write_os_release "$mobile_case/os-release" arch # ignored in Termux
TERMUX_VERSION=0.118 run_setup "$mobile_case/environment" "$mobile_case/os-release" "$mobile_case/user" links
for link in .zshrc .tmux.session.conf .taskrc .config/nvim .config/lazygit/config.yml \
    .termux/termux.properties .termux/colors.properties; do
    [[ -L $mobile_case/user/$link ]] || {
        printf 'Expected mobile link: %s\n' "$link" >&2
        exit 1
    }
done
for link in .config/hypr .config/foot; do
    [[ ! -e $mobile_case/user/$link ]] || {
        printf 'Mobile must not link: %s\n' "$link" >&2
        exit 1
    }
done
[[ $(readlink "$mobile_case/user/.gitconfig.profile") == */git/profile/mobile.gitconfig ]]
[[ -f $mobile_case/user/.taskrc.local && ! -L $mobile_case/user/.taskrc.local ]]
if run_setup "$mobile_case/environment" "$mobile_case/os-release" "$mobile_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected mobile to require Termux.' >&2
    exit 1
fi
for task in desktop docker harden; do
    if TERMUX_VERSION=0.118 run_setup "$mobile_case/environment" "$mobile_case/os-release" "$mobile_case/user" "$task" 2>/dev/null; then
        printf 'Expected %s to reject Termux.\n' "$task" >&2
        exit 1
    fi
done

sailor_case=$test_root/termux-remote
mkdir -p -- "$sailor_case/user"
write_environment "$sailor_case/environment" remote testphone
write_os_release "$sailor_case/os-release" debian debian
TERMUX_VERSION=0.118 run_setup "$sailor_case/environment" "$sailor_case/os-release" "$sailor_case/user" links
[[ -L $sailor_case/user/.termux/termux.properties && -L $sailor_case/user/.vimrc ]]
[[ ! -e $sailor_case/user/.config/nvim && ! -e $sailor_case/user/.taskrc && ! -e $sailor_case/user/.taskrc.local ]]
write_environment "$sailor_case/environment" work testphone
if TERMUX_VERSION=0.118 run_setup "$sailor_case/environment" "$sailor_case/os-release" "$sailor_case/user" links 2>/dev/null; then
    printf '%s\n' 'Expected work to reject Termux.' >&2
    exit 1
fi

legacy_case=$test_root/legacy
mkdir -p -- "$legacy_case/user"
write_environment "$legacy_case/environment" remote testbox
write_os_release "$legacy_case/os-release" debian debian
ln -s "$(cd "$setup_dir/.." && pwd)/shell/.zsh_plugins.txt" "$legacy_case/user/.zsh_plugins.txt"
run_setup "$legacy_case/environment" "$legacy_case/os-release" "$legacy_case/user" links
[[ ! -e $legacy_case/user/.zsh_plugins.txt && ! -L $legacy_case/user/.zsh_plugins.txt ]]

conflict_case=$test_root/conflict
mkdir -p -- "$conflict_case/user"
write_environment "$conflict_case/environment" home testbox
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
for command_name in sudo pacman apt-get pkg; do
    # shellcheck disable=SC2016 # the single quotes keep $* and $@ for the generated shim
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

write_environment "$package_case/environment" remote testbox
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
if grep -q '^apt-get update' "$package_case/commands"; then exit 1; fi
grep -q '^apt-get install' "$package_case/commands"

# Termux installs with pkg (no sudo), and only mobile gets the developer tier.
write_environment "$package_case/environment" mobile phone
: >"$package_case/commands"
TERMUX_VERSION=0.118 WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages
grep -q '^pkg install -y .*termux-api' "$package_case/commands"
grep -q '^pkg install -y .*neovim' "$package_case/commands"
if grep -qE '^(sudo|apt-get)' "$package_case/commands"; then
    printf '%s\n' 'Termux must not use sudo or apt-get.' >&2
    exit 1
fi
write_environment "$package_case/environment" remote testphone
: >"$package_case/commands"
TERMUX_VERSION=0.118 WHC_TEST_LOG=$package_case/commands PATH="$shim_dir:$PATH" \
    run_setup "$package_case/environment" "$package_case/os-release" "$package_case/user" packages
grep -q '^pkg install -y .*mosh' "$package_case/commands"
if grep -q 'neovim' "$package_case/commands"; then
    printf '%s\n' 'A remote Termux phone must not install developer packages.' >&2
    exit 1
fi

# The termux task: script copies (a changed one is backed up), and key-only sshd once a key exists.
termux_case=$test_root/termux
mkdir -p -- "$termux_case/user/.termux" "$termux_case/user/.shortcuts" "$termux_case/user/.ssh"
write_environment "$termux_case/environment" mobile phone
printf 'not the pinned font\n' >"$termux_case/user/.termux/font.ttf"
printf 'edited\n' >"$termux_case/user/.shortcuts/ssh"
for _ in 1 2; do
    TERMUX_VERSION=0.118 WHC_TEST_LOG=$termux_case/commands PATH="$shim_dir:$PATH" WHC_SSHD_DROPIN=$termux_case/sshd.conf \
        run_setup "$termux_case/environment" "$termux_case/os-release" "$termux_case/user" termux >/dev/null 2>"$termux_case/stderr"
done
grep -q 'not the pinned font' "$termux_case/stderr"
grep -q 'no ~/.ssh/authorized_keys' "$termux_case/stderr"
[[ ! -e $termux_case/sshd.conf ]]
cmp -s "$setup_dir/../termux/shortcuts/ssh" "$termux_case/user/.shortcuts/ssh"
[[ -x $termux_case/user/.termux/boot/00-services && ! -L $termux_case/user/.termux/boot/00-services ]]
grep -rqx edited "$termux_case/user/.local/state/whc/backups"
[[ -L $termux_case/user/.termux/colors.properties ]]
printf 'ssh-ed25519 AAAA test\n' >"$termux_case/user/.ssh/authorized_keys"
TERMUX_VERSION=0.118 WHC_TEST_LOG=$termux_case/commands PATH="$shim_dir:$PATH" WHC_SSHD_DROPIN=$termux_case/sshd.conf \
    run_setup "$termux_case/environment" "$termux_case/os-release" "$termux_case/user" termux >/dev/null 2>&1
grep -qx 'PasswordAuthentication no' "$termux_case/sshd.conf"
if TERMUX_VERSION="" PREFIX=/usr run_setup "$home_case/environment" "$home_case/os-release" "$home_case/user" termux 2>/dev/null; then
    printf '%s\n' 'Expected termux to reject a non-Termux machine.' >&2
    exit 1
fi

(
    # shellcheck source=lib/common.sh
    source "$setup_dir/lib/common.sh"
    version_at_least 0.12.5 0.11
    version_at_least 0.11 0.11
    version_at_least 0.12 0.9.5
    if version_at_least 0.10.4 0.11; then exit 1; fi
    if version_at_least 0.9.5 0.11; then exit 1; fi
)

# --relink replaces a wrong symlink; --adopt also backs up a real file. Plain links refuses both.
mode_case=$test_root/mode
mkdir -p -- "$mode_case/user"
write_environment "$mode_case/environment" remote testbox
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
write_environment "$shell_case/environment" remote testbox
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
    grep -q -- "--user tester --cmd 'uwsm start -e -D Hyprland hyprland.desktop'" <<<"$with_uwsm"
    grep -q -- "--user tester --cmd 'start-hyprland'" <<<"$without_uwsm"
    grep -q -- "--cmd 'start-hyprland'" <<<"$opted_out"
    if grep -q '@' <<<"$with_uwsm"; then exit 1; fi
    # tuigreet must receive the session command as ONE --cmd value, and the file must stay valid TOML.
    python3 - "$with_uwsm" <<'PY'
import shlex, sys, tomllib
config = tomllib.loads(sys.argv[1])
arguments = shlex.split(config["default_session"]["command"])
assert arguments[arguments.index("--cmd") + 1] == "uwsm start -e -D Hyprland hyprland.desktop", arguments
assert arguments.count("--cmd") == 1 and arguments[-1] == arguments[arguments.index("--cmd") + 1], arguments
assert arguments[arguments.index("--user") + 1] == "tester", arguments
PY
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
