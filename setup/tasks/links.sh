#!/usr/bin/env bash

# Link groups. A group appends "source|target" pairs to the caller's LINKS array.
link_group() {
    case "$1" in
        shell)
            LINKS+=("$repo_root/shell/.zshrc|$setup_home/.zshrc")
            ;;
        git)
            LINKS+=(
                "$repo_root/git/.gitconfig|$setup_home/.gitconfig"
                "$repo_root/git/.gitignore.global|$setup_home/.gitignore.global"
                "$repo_root/git/profile/$WHC_PROFILE.gitconfig|$setup_home/.gitconfig.profile"
            )
            ;;
        tmux)
            LINKS+=("$repo_root/shell/.tmux.conf|$setup_home/.tmux.conf")
            if profile_has dev; then
                LINKS+=("$repo_root/shell/.tmux.session.conf|$setup_home/.tmux.session.conf")
            fi
            ;;
        vim)
            LINKS+=("$repo_root/vim/.vimrc|$setup_home/.vimrc")
            ;;
        nvim)
            LINKS+=("$repo_root/nvim|$setup_config_home/nvim")
            ;;
        node)
            LINKS+=(
                "$repo_root/node/.npmrc|$setup_home/.npmrc"
                "$repo_root/node/.yarnrc.yml|$setup_home/.yarnrc.yml"
            )
            ;;
        tasks)
            LINKS+=("$repo_root/taskwarrior/.taskrc|$setup_home/.taskrc")
            ;;
        desktop)
            LINKS+=(
                "$repo_root/hypr|$setup_config_home/hypr"
                "$repo_root/swayimg|$setup_config_home/swayimg"
                "$repo_root/walker/config.toml|$setup_config_home/walker/config.toml"
                "$repo_root/walker/menus/projects.lua|$setup_config_home/elephant/menus/projects.lua"
                "$repo_root/walker/menus/session.toml|$setup_config_home/elephant/menus/session.toml"
                "$repo_root/walker/applications/whc-projects.desktop|${XDG_DATA_HOME:-$setup_home/.local/share}/applications/whc-projects.desktop"
                "$repo_root/misc/mimeapps.list|$setup_config_home/mimeapps.list"
                "$repo_root/misc/chrome-flags.conf|$setup_config_home/chrome-flags.conf"
                "$repo_root/misc/chromium-flags.conf|$setup_config_home/chromium-flags.conf"
            )
            ;;
        *) die "unknown link group '$1'" ;;
    esac
}

# The groups each profile receives: remote is the lightweight baseline,
# work adds the developer tooling, and home adds the desktop.
profile_link_groups() {
    printf '%s\n' shell git tmux vim
    if profile_has dev; then
        printf '%s\n' nvim node tasks
    fi
    if profile_has desktop; then
        printf '%s\n' desktop
    fi
}

link_groups() {
    local group
    local -a LINKS=()
    for group in "$@"; do
        link_group "$group"
    done
    link_set LINKS
}

# Links from earlier layouts that no longer have a source in the repo.
remove_legacy_links() {
    local target=$setup_home/.zsh_plugins.txt
    if [[ -L $target && $(readlink -- "$target") == "$repo_root"/shell/* ]]; then
        rm -- "$target"
        printf 'Removed legacy link %s\n' "$target"
    fi
}

task_links() {
    local -a groups
    mapfile -t groups < <(profile_link_groups)
    remove_legacy_links
    link_groups "${groups[@]}"
}
