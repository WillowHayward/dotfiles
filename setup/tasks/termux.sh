#!/usr/bin/env bash

# Termux (Android) integration for phones: terminal settings, font, Termux:Widget shortcuts,
# a Termux:Boot script and sshd. Runs on any profile installed in Termux (mobile for a daily
# phone, remote for a test device). The companion apps come from F-Droid, like Termux itself.

# Termux:Widget and Termux:Boot refuse scripts whose real path is outside their directories,
# so these are installed as copies rather than links (a changed copy is backed up first).
install_script_copies() {
    local source_dir=$1 target_dir=$2 source target
    mkdir -p -- "$target_dir"
    for source in "$source_dir"/*; do
        [[ -f $source ]] || continue
        target=$target_dir/$(basename -- "$source")
        if [[ -e $target || -L $target ]]; then
            cmp -s -- "$source" "$target" && [[ ! -L $target ]] && continue
            backup_target "$target"
        fi
        install -m 0700 -- "$source" "$target"
        printf 'Installed %s\n' "$target"
    done
}

install_termux_font() {
    local target=$setup_home/.termux/font.ttf tmp
    if [[ -e $target ]]; then
        printf '%s  %s\n' "$TERMUX_FONT_SHA256" "$target" | sha256sum -c - >/dev/null 2>&1 && return 0
        warn "$target is not the pinned font; leaving it (delete it to install JetBrains Mono Nerd Font)."
        return 0
    fi
    tmp=$(mktemp)
    trap 'rm -f -- "$tmp"' RETURN
    download_verified \
        "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/patched-fonts/JetBrainsMono/Ligatures/JetBrainsMonoNerdFontMono-Regular.ttf" \
        "$TERMUX_FONT_SHA256" "$tmp"
    mkdir -p -- "$(dirname -- "$target")"
    install -m 0644 -- "$tmp" "$target"
    rm -f -- "$tmp"
    trap - RETURN
    printf 'Installed %s\n' "$target"
}

# Key-only logins once a key is authorised (Termux's sshd listens on 8022). Physical access
# to the phone recovers from a mistake, so this does not ask first.
configure_termux_sshd() {
    local keys=$setup_home/.ssh/authorized_keys dropin=${WHC_SSHD_DROPIN:-${PREFIX:-}/etc/ssh/sshd_config.d/10-dotfiles.conf}
    local body=$'# Managed by dotfiles (setup/tasks/termux.sh).\nPasswordAuthentication no\nKbdInteractiveAuthentication no\n'
    if [[ ! -s $keys ]]; then
        warn "no ~/.ssh/authorized_keys yet: sshd keeps password logins until you add a key and rerun this task."
        return 0
    fi
    if [[ ! -e $dropin || $(<"$dropin") != "${body%$'\n'}" ]]; then
        mkdir -p -- "$(dirname -- "$dropin")"
        printf '%s' "$body" >"$dropin"
        printf 'Disabled sshd password logins (%s)\n' "$dropin"
    fi
    [[ $setup_home == "$HOME" ]] || return 0
    if command -v sv-enable >/dev/null 2>&1 && [[ -n ${SVDIR:-} ]]; then
        sv-enable sshd >/dev/null && printf 'sshd enabled (port 8022); it starts with Termux:Boot.\n'
    else
        warn "termux-services is not running yet: restart Termux, then run 'just setup termux' again to enable sshd."
    fi
}

task_termux() {
    [[ $PACKAGE_FAMILY == termux ]] || die "termux only applies to profiles installed in Termux."
    install_packages termux-api termux-services openssh fzf mosh
    link_groups termux
    install_termux_font
    install_script_copies "$repo_root/termux/shortcuts" "$setup_home/.shortcuts"
    install_script_copies "$repo_root/termux/boot" "$setup_home/.termux/boot"
    configure_termux_sshd
    if [[ $setup_home == "$HOME" ]] && command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings
    fi
    cat <<'NOTE'
Termux configured. Once per phone, by hand:
  - Install Termux:API, Termux:Boot and Termux:Widget from the same source as Termux
    (F-Droid or GitHub), open Termux:Boot once, and exempt Termux from battery optimisation.
  - termux-setup-storage   (shared storage at ~/storage, e.g. the Obsidian vault)
NOTE
}
