#!/usr/bin/env bash

task_manual_lock() {
    [[ $WHC_PROFILE == home ]] || die "manual-lock is only supported by the home profile."

    local -a user_links=("$repo_root/hypr|$setup_config_home/hypr")
    local -a system_links=(
        "$repo_root/greetd/config.toml|/etc/greetd/config.toml"
        "$repo_root/systemd/logind.conf|/etc/systemd/logind.conf.d/60-manual-power.conf"
        "$repo_root/systemd/logind-dotfiles.conf|/etc/systemd/system/systemd-logind.service.d/60-dotfiles.conf"
    )
    local item source target failed=false
    for item in "${user_links[@]}" "${system_links[@]}"; do
        source=${item%%|*}
        target=${item#*|}
        check_link "$source" "$target" || failed=true
    done
    [[ $failed == false ]] || die "resolve the manual-lock link conflicts above and run setup again."

    install_packages greetd-tuigreet hyprlock hypridle
    link_set user_links
    for item in "${system_links[@]}"; do
        source=${item%%|*}
        target=${item#*|}
        paths_match "$source" "$target" && continue
        run_as_root install -d "$(dirname -- "$target")"
        run_as_root ln -s -- "$source" "$target"
        printf 'Linked %s -> %s\n' "$target" "$source"
    done
    run_as_root systemctl daemon-reload
    printf '%s\n' 'Manual locking configured. Reboot to apply the logind sandbox change.'
}
