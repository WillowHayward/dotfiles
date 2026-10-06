#!/usr/bin/env bash

# Render greetd/config.toml.in: the installing user and the session launcher are filled in
# at install time instead of being committed. uwsm (a systemd-managed session) is used when
# installed, with the same arguments as Hyprland's own hyprland-uwsm.desktop; WHC_NO_UWSM=1 keeps
# the plain start-hyprland wrapper. The command is single-quoted so tuigreet receives it as one
# --cmd value (unquoted, it would run just `uwsm` and fail after login).
render_greetd_config() {
    local user=$1 uwsm_available=$2 command=start-hyprland
    if [[ $uwsm_available == yes && ${WHC_NO_UWSM:-} != 1 ]]; then
        command="uwsm start -e -D Hyprland hyprland.desktop"
    fi
    sed -e "s|@USER@|$user|g" -e "s|@SESSION_COMMAND@|$command|g" "$repo_root/greetd/config.toml.in"
}

# Copy (not symlink) the system files: root-owned files should not depend on a path inside
# $HOME, and logind's sandbox cannot see $HOME anyway. Rerun this task to apply edits.
task_manual_lock() {
    [[ $WHC_PROFILE == home ]] || die "manual-lock is only supported by the home profile."
    # Run as your own user: the task calls sudo itself, and under sudo the greeter would be
    # rendered for root and the links would land in root's home.
    ((EUID != 0)) || die "run manual-lock as your own user, not as root or with sudo."

    install_packages greetd-tuigreet hyprlock hypridle uwsm
    link_groups hypr

    local uwsm=no rendered
    command -v uwsm >/dev/null 2>&1 && uwsm=yes
    rendered=$(mktemp)
    trap 'rm -f -- "$rendered"' RETURN
    render_greetd_config "$(id -un)" "$uwsm" >"$rendered"

    run_as_root install -d /etc/greetd /etc/systemd/logind.conf.d
    run_as_root install -m 0644 "$rendered" /etc/greetd/config.toml
    run_as_root install -m 0644 "$repo_root/systemd/logind.conf" /etc/systemd/logind.conf.d/60-manual-power.conf
    # Earlier versions symlinked these and used a drop-in to expose the repo to logind.
    run_as_root rm -f /etc/systemd/system/systemd-logind.service.d/60-dotfiles.conf
    run_as_root rmdir --ignore-fail-on-non-empty /etc/systemd/system/systemd-logind.service.d 2>/dev/null || true
    run_as_root systemctl daemon-reload
    printf 'Installed greetd and logind configuration (session: %s).\n' "$(grep -o 'cmd .*"' /etc/greetd/config.toml | head -1)"
    printf '%s\n' 'Reboot to apply. If login fails, switch to a TTY (Ctrl+Alt+F2) and run WHC_NO_UWSM=1 just setup manual-lock.'
}
