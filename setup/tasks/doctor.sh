#!/usr/bin/env bash

# Report what this machine is missing for its profile. Exits non-zero when a required
# tool or link is missing; warnings (old versions, drift, stale builds) do not fail it.
doctor_failed=false

doctor_ok() { printf '  ok       %s\n' "$*"; }
doctor_warn() { printf '  WARN     %s\n' "$*"; }
doctor_miss() {
    printf '  MISSING  %s\n' "$*"
    doctor_failed=true
}

doctor_commands() {
    local label=$1 command
    shift
    printf '%s\n' "$label"
    for command in "$@"; do
        if command -v "$command" >/dev/null 2>&1; then
            doctor_ok "$command"
        else
            doctor_miss "$command"
        fi
    done
}

doctor_optional() {
    local command
    for command in "$@"; do
        command -v "$command" >/dev/null 2>&1 && doctor_ok "$command (optional)" || doctor_warn "$command (optional) not installed"
    done
}

doctor_links() {
    local group item source target
    local -a groups
    local -a LINKS=()
    mapfile -t groups < <(profile_link_groups)
    for group in "${groups[@]}"; do link_group "$group"; done
    printf 'links\n'
    for item in "${LINKS[@]}"; do
        source=${item%%|*}
        target=${item#*|}
        if paths_match "$source" "$target"; then
            doctor_ok "$target"
        elif [[ -e $target || -L $target ]]; then
            doctor_miss "$target exists but is not linked to the repo (links --relink / --adopt)"
        else
            doctor_miss "$target is not linked (just setup links)"
        fi
    done
}

# Plugins on disk should match lazy-lock.json (Neovim reports drift by name).
doctor_nvim_lock() {
    local lock=$repo_root/nvim/lazy-lock.json plugins=${XDG_DATA_HOME:-$setup_home/.local/share}/nvim/lazy
    [[ -r $lock && -d $plugins ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0
    local drift
    drift=$(
        python3 - "$lock" "$plugins" <<'PY'
import json, subprocess, sys
lock = json.load(open(sys.argv[1]))
drift = []
for name, info in lock.items():
    head = subprocess.run(["git", "-C", f"{sys.argv[2]}/{name}", "rev-parse", "HEAD"],
                          capture_output=True, text=True).stdout.strip()
    if head and head != info["commit"]:
        drift.append(name)
print(" ".join(drift))
PY
    )
    [[ -z $drift ]] && doctor_ok "Neovim plugins match lazy-lock.json" ||
        doctor_warn "Neovim plugins differ from lazy-lock.json: $drift (:Lazy restore, or commit the lockfile)"
}

# The hand-built desktop binaries must be rebuilt after Hyprland or Qt upgrades.
doctor_stale_builds() {
    local plugin=$setup_home/.local/lib/hyprland/hyprbars.so flameshot=$setup_home/.local/lib/flameshot-hyprland/flameshot
    if [[ -e $plugin ]]; then
        [[ $plugin -nt $(command -v Hyprland) ]] && doctor_ok "hyprbars is newer than Hyprland" ||
            doctor_warn "hyprbars is older than Hyprland: run hypr/install-hyprbars.sh"
    fi
    if [[ -e $flameshot ]]; then
        local qt
        qt=$(ls /usr/lib/libQt6Core.so.6 2>/dev/null || true)
        [[ -z $qt || $flameshot -nt $qt ]] && doctor_ok "patched flameshot is newer than Qt" ||
            doctor_warn "patched flameshot is older than Qt: run hypr/install-flameshot.sh"
    fi
}

task_doctor() {
    printf 'Profile %s (%s), device %s\n' "$WHC_PROFILE" "$PACKAGE_FAMILY" "${WHC_DEVICE:-unset}"
    doctor_commands "core tools" git zsh tmux fzf rg curl less delta jq bat
    if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then doctor_ok fd; else doctor_miss fd; fi
    if [[ $WHC_PROFILE == remote ]]; then doctor_commands "editor" vim; else doctor_optional vim; fi
    doctor_optional eza zoxide atuin
    if profile_has dev; then
        doctor_commands "developer tools" nvim fnm node tree-sitter lazygit gh direnv uv task shfmt
        local current
        current=$(installed_nvim_version || true)
        if [[ -n $current ]] && version_at_least "$current" "$nvim_minimum_version"; then
            doctor_ok "nvim $current (needs $nvim_minimum_version+)"
        else
            doctor_miss "nvim $nvim_minimum_version+ (found: ${current:-none})"
        fi
        doctor_nvim_lock
    fi
    if profile_has desktop; then
        doctor_commands "desktop" hyprctl Hyprland walker elephant foot flameshot grim wpctl playerctl brightnessctl notify-send
        doctor_stale_builds
    fi
    if [[ $WHC_PROFILE == remote ]]; then
        doctor_commands "server" docker
    fi
    doctor_links
    [[ $doctor_failed == false ]] || die "doctor found problems."
    printf 'All required checks passed.\n'
}
