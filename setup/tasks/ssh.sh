#!/usr/bin/env bash

# Make ssh pick up per-host files and the shared defaults without replacing ~/.ssh/config:
# `Include ~/.ssh/config.d/*` goes first (host entries beat the defaults), the repo's
# defaults go last. Both lines carry a marker so reruns change nothing.
ssh_marker='# whc-dotfiles'

task_ssh() {
    local ssh_dir=$setup_home/.ssh config=$setup_home/.ssh/config defaults=$repo_root/ssh/defaults.conf
    install -d -m 700 -- "$ssh_dir" "$ssh_dir/config.d" "$ssh_dir/control"
    [[ -e $config ]] || install -m 600 /dev/null "$config"
    if ! grep -qF "$ssh_marker config.d" "$config"; then
        cp -- "$config" "$config.pre-dotfiles"
        {
            printf 'Include ~/.ssh/config.d/* %s config.d\n\n' "$ssh_marker"
            cat "$config.pre-dotfiles"
        } >"$config"
    fi
    if ! grep -qF "$ssh_marker defaults" "$config"; then
        printf '\nInclude %s %s defaults\n' "$defaults" "$ssh_marker" >>"$config"
    fi
    chmod 600 -- "$config"

    # Allowed signers let `git log --show-signature` verify the SSH-signed commits (home and
    # mobile; each machine signs with its own key, so add the others' keys to this file by hand).
    local pub=$ssh_dir/id_ed25519.pub signers=$ssh_dir/allowed_signers
    if [[ ($WHC_PROFILE == home || $WHC_PROFILE == mobile) && -r $pub && ! -e $signers ]]; then
        printf 'willow@whc.fyi namespaces="git" %s\n' "$(cat "$pub")" >"$signers"
        chmod 644 -- "$signers"
    fi
}
