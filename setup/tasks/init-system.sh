#!/usr/bin/env bash

prompt_profile() {
    local current=$1 answer
    while true; do
        printf '\nWHC_PROFILE determines the operating-system setup path:\n' >&2
        printf '  1) home   (Arch)\n  2) work   (Debian family)\n  3) remote (Debian family)\n' >&2
        [[ -n $current ]] && printf 'Press Enter to keep: %s\n' "$current" >&2
        read -r -p 'Profile [1-3]: ' answer
        [[ -z $answer && -n $current ]] && answer=$current
        case "$answer" in
            1|home) printf 'home\n'; return ;;
            2|work) printf 'work\n'; return ;;
            3|remote) printf 'remote\n'; return ;;
            *) printf 'Choose home, work, or remote.\n' >&2 ;;
        esac
    done
}

valid_device() {
    [[ -n $1 && $1 != *$'\n'* && $1 != *$'\r'* && $1 != *\"* && $1 != *\\* ]]
}

prompt_device() {
    local current=$1 answer custom
    while true; do
        printf '\nWHC_DEVICE names this machine:\n' >&2
        printf '  1) cowgirl\n  2) bessie\n  3) ship\n  4) work\n  5) custom\n' >&2
        [[ -n $current ]] && printf 'Press Enter to keep: %s\n' "$current" >&2
        read -r -p 'Device [1-5]: ' answer
        [[ -z $answer && -n $current ]] && answer=$current
        case "$answer" in
            1|cowgirl) printf 'cowgirl\n'; return ;;
            2|bessie) printf 'bessie\n'; return ;;
            3|ship) printf 'ship\n'; return ;;
            4|work) printf 'work\n'; return ;;
            5|custom)
                read -r -p 'Custom device name: ' custom
                if valid_device "$custom"; then
                    printf '%s\n' "$custom"
                    return
                fi
                printf 'Device name must be non-empty and cannot contain quotes, backslashes, or newlines.\n' >&2
                ;;
            *)
                if valid_device "$answer"; then
                    printf '%s\n' "$answer"
                    return
                fi
                printf 'Choose a preset or enter a valid custom device name.\n' >&2
                ;;
        esac
    done
}

write_system_identity() {
    local profile=$1 device=$2 temp
    temp=$(mktemp)
    trap 'rm -f -- "$temp"' RETURN
    if [[ -r $environment_file ]]; then
        awk '!/^[[:space:]]*(WHC_PROFILE|WHC_DEVICE)[[:space:]]*=/' "$environment_file" > "$temp"
    fi
    printf 'WHC_PROFILE="%s"\nWHC_DEVICE="%s"\n' "$profile" "$device" >> "$temp"
    if [[ $environment_file == /etc/environment ]]; then
        run_as_root install -m 0644 "$temp" "$environment_file"
    else
        install -m 0644 "$temp" "$environment_file"
    fi
    rm -f -- "$temp"
    trap - RETURN
}

task_init_system() {
    [[ -t 0 ]] || die "init-system requires an interactive terminal."
    local current_profile= current_device= profile device confirmation
    current_profile=$(read_environment_value WHC_PROFILE 2>/dev/null || true)
    current_device=$(read_environment_value WHC_DEVICE 2>/dev/null || true)
    [[ $current_profile == home || $current_profile == work || $current_profile == remote ]] \
        || current_profile=
    valid_device "$current_device" || current_device=

    profile=$(prompt_profile "$current_profile")
    device=$(prompt_device "$current_device")
    printf '\nProfile: %s\nDevice:  %s\n' "$profile" "$device"
    read -r -p 'Write these values to /etc/environment? [y/N] ' confirmation
    [[ $confirmation == y || $confirmation == Y ]] || { printf 'No changes made.\n'; return; }

    write_system_identity "$profile" "$device"
    printf '%s\n' 'System identity updated. New login sessions will inherit it automatically.'
}
