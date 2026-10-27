#!/usr/bin/env bash

# Render greetd/config.toml.in: the installing user and the session launcher are filled in
# at install time instead of being committed. uwsm (a systemd-managed session) is used when
# installed, with the same arguments as Hyprland's own hyprland-uwsm.desktop; WHC_NO_UWSM=1 keeps
# the plain start-hyprland wrapper. The command is single-quoted so tuigreet receives it as one
# --cmd value (unquoted, it would run just `uwsm` and fail after login).
#
# With autologin=yes (WHC_AUTOLOGIN=1 in /etc/environment, for always-on machines such as Ranch)
# greetd's [initial_session] logs the user in once at boot, so the session and its user services
# come up unattended; logging out returns to tuigreet. The session leaves a marker in
# $XDG_RUNTIME_DIR that makes Hyprland lock the screen straight away (hypr/startup.lua).
render_greetd_config() {
    local user=$1 uwsm_available=$2 autologin=${3:-no} command=start-hyprland
    if [[ $uwsm_available == yes && ${WHC_NO_UWSM:-} != 1 ]]; then
        command="uwsm start -e -D Hyprland hyprland.desktop"
    fi
    sed -e "s|@USER@|$user|g" -e "s|@SESSION_COMMAND@|$command|g" "$repo_root/greetd/config.toml.in"
    [[ $autologin == yes ]] || return 0
    cat <<EOF

# Rendered because WHC_AUTOLOGIN=1: log $user in once at boot, then lock (hypr/startup.lua).
[initial_session]
command = "sh -c 'touch \\"\$XDG_RUNTIME_DIR/whc-autologin\\"; exec $command'"
user = "$user"
EOF
}

# WHC_AUTOLOGIN from /etc/environment: 1/yes/true turns automatic login on.
autologin_wanted() {
    local value
    value=$(read_environment_value WHC_AUTOLOGIN) || return 1
    [[ ${value,,} == 1 || ${value,,} == yes || ${value,,} == true ]]
}

# Copy (not symlink) the system files: root-owned files should not depend on a path inside
# $HOME, and logind's sandbox cannot see $HOME anyway. Rerun this task to apply edits.
task_manual_lock() {
    [[ $WHC_PROFILE == home ]] || die "manual-lock is only supported by the home profile."
    # Run as your own user: the task calls sudo itself, and under sudo the greeter would be
    # rendered for root and the links would land in root's home.
    ((EUID != 0)) || die "run manual-lock as your own user, not as root or with sudo."

    install_packages greetd-tuigreet hyprlock hypridle uwsm
    link_stacks hypr

    local uwsm=no autologin=no rendered
    command -v uwsm >/dev/null 2>&1 && uwsm=yes
    autologin_wanted && autologin=yes
    rendered=$(mktemp)
    trap 'rm -f -- "$rendered"' RETURN
    render_greetd_config "$(id -un)" "$uwsm" "$autologin" >"$rendered"

    run_as_root install -d /etc/greetd /etc/systemd/logind.conf.d
    run_as_root install -m 0644 "$rendered" /etc/greetd/config.toml
    run_as_root install -m 0644 "$repo_root/systemd/logind.conf" /etc/systemd/logind.conf.d/60-manual-power.conf
    # Earlier versions symlinked these and used a drop-in to expose the repo to logind.
    run_as_root rm -f /etc/systemd/system/systemd-logind.service.d/60-dotfiles.conf
    run_as_root rmdir --ignore-fail-on-non-empty /etc/systemd/system/systemd-logind.service.d 2>/dev/null || true
    run_as_root systemctl daemon-reload
    printf 'Installed greetd and logind configuration (session: %s; automatic login: %s).\n' \
        "$(grep -o 'cmd .*"' /etc/greetd/config.toml | head -1)" "$autologin"
    printf '%s\n' 'Reboot to apply. If login fails, switch to a TTY (Ctrl+Alt+F2) and run WHC_NO_UWSM=1 just setup manual-lock.'
}
