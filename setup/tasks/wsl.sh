#!/usr/bin/env bash

# Install the WSL config templates in work/: /etc/wsl.conf inside the distribution, and
# .wslconfig on the Windows side (written only if missing; existing files are only reported).
is_wsl() {
    [[ -n ${WSL_DISTRO_NAME:-} ]] || grep -qi microsoft /proc/version 2>/dev/null
}

confirm() {
    [[ ${WHC_ASSUME_YES:-} == 1 ]] && return 0
    local answer
    read -r -p "$1 [y/N] " answer
    [[ $answer == y || $answer == Y ]]
}

task_wsl() {
    [[ $WHC_PROFILE == work ]] || die "wsl is only supported by the work profile."
    is_wsl || die "this does not look like WSL."
    local template=$repo_root/work/wsl.conf target=${WHC_WSL_CONF:-/etc/wsl.conf}
    if [[ -e $target ]] && cmp -s "$template" "$target"; then
        printf '%s is up to date.\n' "$target"
    else
        [[ ! -e $target ]] || diff -u "$target" "$template" || true
        if confirm "Install $template as $target? (takes effect after 'wsl --shutdown' in Windows)"; then
            run_as_root install -m 0644 "$template" "$target"
        fi
    fi

    local windows_home
    if command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
        windows_home=$(wslpath "$(cmd.exe /c 'echo %UserProfile%' 2>/dev/null | tr -d '\r')" 2>/dev/null || true)
    fi
    if [[ -n ${windows_home:-} ]]; then
        if [[ -e $windows_home/.wslconfig ]]; then
            printf '%s already exists; compare it with %s by hand.\n' "$windows_home/.wslconfig" "$repo_root/work/wslconfig"
        elif confirm "Create $windows_home/.wslconfig from work/wslconfig?"; then
            install -m 0644 "$repo_root/work/wslconfig" "$windows_home/.wslconfig"
        fi
    else
        printf 'Copy %s to %%UserProfile%%\\.wslconfig in Windows, then run: wsl --shutdown\n' "$repo_root/work/wslconfig"
    fi
}
