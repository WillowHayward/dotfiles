#!/usr/bin/env bash

# Baseline server hardening for the remote profile. Deliberately small, and a candidate
# to move into the infra repo (see docs/future-willow.md). Each step explains itself and
# asks before changing anything; WHC_ASSUME_YES=1 skips the questions and
# WHC_HARDEN_STEPS (default "ssh,upgrades,ufw") picks the steps. fail2ban joins with
# WHC_HARDEN_FAIL2BAN=1. Nothing here runs from `all`.
harden_step() {
    [[ ,${WHC_HARDEN_STEPS:-ssh,upgrades,ufw}, == *",$1,"* ]]
}

harden_confirm() {
    [[ ${WHC_ASSUME_YES:-} == 1 ]] && return 0
    local answer
    read -r -p "$1 [y/N] " answer
    [[ $answer == y || $answer == Y ]]
}

harden_ssh() {
    local dropin=${WHC_SSHD_DROPIN:-/etc/ssh/sshd_config.d/10-dotfiles.conf} keys=$setup_home/.ssh/authorized_keys
    # Lock-out guard: never disable passwords unless this user can log in with a key.
    [[ -s $keys ]] || die "$keys is empty; add your public key before disabling password logins."
    local proposal
    proposal=$(mktemp)
    printf '# Managed by dotfiles (setup/tasks/harden.sh).\nPermitRootLogin no\nPasswordAuthentication no\nKbdInteractiveAuthentication no\n' >"$proposal"
    if [[ -e $dropin ]] && cmp -s "$proposal" "$dropin"; then
        printf 'sshd hardening already in place.\n'
        rm -f -- "$proposal"
        return
    fi
    printf 'sshd would get %s:\n' "$dropin"
    cat -- "$proposal"
    harden_confirm "Keep another session open. Apply and reload sshd?" || {
        rm -f -- "$proposal"
        return
    }
    run_as_root install -d -m 0755 "$(dirname -- "$dropin")"
    run_as_root install -m 0644 "$proposal" "$dropin"
    rm -f -- "$proposal"
    if ! run_as_root sshd -t; then
        run_as_root rm -f -- "$dropin"
        die "sshd rejected the new configuration; removed it again."
    fi
    run_as_root systemctl reload ssh 2>/dev/null || run_as_root systemctl reload sshd 2>/dev/null ||
        warn "could not reload sshd; the change applies on its next restart."
}

harden_upgrades() {
    install_packages unattended-upgrades
    harden_confirm "Enable automatic security updates (unattended-upgrades)?" || return 0
    printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' |
        run_as_root tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null
}

harden_ufw() {
    install_packages ufw
    local port
    local -a ports
    mapfile -t ports < <(run_as_root sshd -T 2>/dev/null | awk '$1 == "port" { print $2 }')
    ((${#ports[@]} > 0)) || ports=(22)
    printf 'ufw would deny incoming traffic and allow SSH on port(s): %s\n' "${ports[*]}"
    printf 'Note: published Docker ports bypass ufw; restrict those in the compose files.\n'
    harden_confirm "Apply and enable the firewall?" || return 0
    for port in "${ports[@]}"; do run_as_root ufw allow "$port/tcp"; done
    run_as_root ufw default deny incoming
    run_as_root ufw default allow outgoing
    run_as_root ufw --force enable
}

task_harden() {
    [[ $WHC_PROFILE == remote ]] || die "harden is only supported by the remote profile."
    harden_step ssh && harden_ssh
    harden_step upgrades && harden_upgrades
    harden_step ufw && harden_ufw
    if [[ ${WHC_HARDEN_FAIL2BAN:-} == 1 ]]; then
        install_packages fail2ban
    fi
    printf 'Hardening finished.\n'
}
