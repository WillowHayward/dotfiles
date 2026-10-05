# Directory shortcuts: cdd (dotfiles), cdp (projects), cdi (infra).
#
#   cdp           cd to $WHC_PROJECTS_DIR
#   cdp <name>    cd to the immediate subdirectory $WHC_PROJECTS_DIR/<name>
#
# The roots come from WHC_DOTFILES_DIR, WHC_PROJECTS_DIR and WHC_INFRA_DIR
# (defaults and overrides: core/env.zsh and .env). Only immediate subdirectories
# are accepted, and tab completion offers exactly those.
typeset -gA _whc_cd_roots=(cdd WHC_DOTFILES_DIR cdp WHC_PROJECTS_DIR cdi WHC_INFRA_DIR)

_whc_cd() {
    local command=$1 name=${2-}
    name=${name%/}
    local root=${(P)_whc_cd_roots[$command]}
    if [[ -z $root || ! -d $root ]]; then
        print -u2 "$command: ${_whc_cd_roots[$command]} (${root:-unset}) is not a directory"
        return 1
    fi
    if (( $# > 2 )); then
        print -u2 "$command: expected at most one argument"
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
    local -a dirs
    (( CURRENT == 2 )) || return 1
    [[ -d $root ]] || return 1
    if [[ $PREFIX == .* ]]; then
        dirs=("$root"/*(ND/:t))
    else
        dirs=("$root"/*(N/:t))
    fi
    compadd -- $dirs
}

compdef _whc_cd_complete cdd cdp cdi
