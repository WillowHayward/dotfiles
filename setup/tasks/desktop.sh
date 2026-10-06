#!/usr/bin/env bash

# User-level desktop setup for the home profile: packages and ~/.config links.
# System-level login/lock configuration is the separate, opt-in manual-lock task.
task_desktop() {
    [[ $WHC_PROFILE == home ]] || die "desktop is only supported by the home profile."
    local -a packages
    mapfile -t packages < <(tier_packages desktop)
    install_packages "${packages[@]}"
    link_groups desktop
    local applications=$setup_data_home/applications
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$applications"
    fi
    # Hyprland starts both user services (hypr/startup.lua); Elephant also starts with the session.
    if [[ $setup_home == "$HOME" ]] && command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload || warn "could not reload the systemd user manager."
        systemctl --user enable elephant.service || warn "could not enable elephant.service."
    fi
    warn "AUR packages are not installed automatically: walker-bin elephant-all hyprmon-bin."
    printf '%s\n' 'Desktop configured. Restart Elephant to load the project and session menus.'
}
