#!/usr/bin/env bash

# User-level desktop setup for the home profile: packages and ~/.config links.
# System-level login/lock configuration is the separate, opt-in manual-lock task.
task_desktop() {
    [[ $WHC_PROFILE == home ]] || die "desktop is only supported by the home profile."
    local -a packages
    mapfile -t packages < <(tier_packages desktop)
    mapfile -t -O "${#packages[@]}" packages < <(tier_packages apps)
    install_packages "${packages[@]}"
    link_stacks hypr swayimg walker misc foot mako gtk-3.0 gtk-4.0 xdg-desktop-portal systemd
    # Desktop colours outside the dotfiles: GTK 4 colour scheme and accent (gsettings), Walker, Firefox.
    if [[ $setup_home == "$HOME" ]] && command -v python3 >/dev/null 2>&1; then
        local theme
        theme=$(sed -n 's/^theme = "\(.*\)"$/\1/p' "$repo_root/whc-theme/theme.toml")
        python3 "$repo_root/whc-theme/whc-theme" apply "${theme:-meadow-night}" --targets machine ||
            warn "whc-theme could not theme the desktop apps; run \`just theme-apply\`."
    fi
    local applications=$setup_data_home/applications
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$applications"
    fi
    # Hyprland starts both user services (hypr/startup.lua); Elephant also starts with the session.
    if [[ $setup_home == "$HOME" ]] && command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload || warn "could not reload the systemd user manager."
        systemctl --user enable elephant.service || warn "could not enable elephant.service."
    fi
    warn "AUR packages are not installed automatically: $(tier_packages aur | paste -sd' ')."
    printf '%s\n' 'Desktop configured. Restart Elephant to load the project and session menus.'
}
