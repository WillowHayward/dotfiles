# Directory shortcuts: cdd (dotfiles), cdp (projects), cdi (infra).
#
#   cdp           cd to $WHC_PROJECTS_DIR
#   cdp <name>    cd to the immediate subdirectory $WHC_PROJECTS_DIR/<name>, or
#                 $WHC_LOCAL_PROJECTS_DIR/<name> for a project kept on the internal disk
#
# The roots come from WHC_DOTFILES_DIR, WHC_PROJECTS_DIR and WHC_INFRA_DIR
# (defaults and overrides: /etc/environment, core/env.zsh and .env). Only immediate
# subdirectories are accepted, and tab completion offers exactly those.
typeset -gA _whc_cd_roots=(cdd WHC_DOTFILES_DIR cdp WHC_PROJECTS_DIR cdi WHC_INFRA_DIR)
# Optional second roots searched for <name>; a project lives in only one of them.
typeset -gA _whc_cd_local_roots=(cdp WHC_LOCAL_PROJECTS_DIR)

_whc_cd() {
    local command=$1 name=${2-}
    name=${name%/}
    local root=${(P)_whc_cd_roots[$command]}
    local local_var=${_whc_cd_local_roots[$command]-} local_root=
    [[ -z $local_var ]] || local_root=${(P)local_var-}
    if (( $# > 2 )); then
        print -u2 "$command: expected at most one argument"
        return 1
    fi
    # Checked before the main root so local projects work while the drive is unplugged.
    if [[ -n $name && -n $local_root && $name != */* && $name != (.|..) && -d $local_root/$name ]]; then
        cd -- "$local_root/$name"
        return
    fi
    if [[ -z $root || ! -d $root ]]; then
        print -u2 "$command: ${_whc_cd_roots[$command]} (${root:-unset}) is not a directory"
        return 1
    fi
    if [[ -z $name ]]; then
        cd -- "$root"
    elif [[ $name == */* || $name == . || $name == .. ]]; then
        print -u2 "$command: '$name' is not an immediate subdirectory of $root"
        return 1
    elif [[ -d $root/$name ]]; then
        cd -- "$root/$name"
    else
        print -u2 "$command: no such directory: $root/$name"
        return 1
    fi
}

cdd() { _whc_cd cdd "$@" }
cdp() { _whc_cd cdp "$@" }
cdi() { _whc_cd cdi "$@" }

# Completion: immediate subdirectories only; hidden ones when the word starts with a dot.
_whc_cd_complete() {
    local root=${(P)_whc_cd_roots[$service]}
    local local_var=${_whc_cd_local_roots[$service]-} local_root=
    [[ -z $local_var ]] || local_root=${(P)local_var-}
    local -a dirs
    (( CURRENT == 2 )) || return 1
    for root in $root $local_root; do
        [[ -d $root ]] || continue
        if [[ $PREFIX == .* ]]; then
            dirs+=("$root"/*(ND/:t))
        else
            dirs+=("$root"/*(N/:t))
        fi
    done
    (( $#dirs )) || return 1
    compadd -- ${(u)dirs}
}

compdef _whc_cd_complete cdd cdp cdi
