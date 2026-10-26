# Open configured projects through the same backend as Walker.
#
#   pp                                 pick a project (prototypes are listed as proto/<name>)
#   pp <project>                       open a project by label, basename or path
#   pp --refresh [project]             rename a running session after a .whc/.ticket/branch change
#   pp --new [--prototypes] [--local] <name>
#                                      create <name> (nested a/b is fine), git init it and open it;
#                                      under $WHC_PROTO_DIR with --prototypes, else $WHC_PROJECTS_DIR;
#                                      --local uses the WHC_LOCAL_* root instead, so it works undocked
#                                      (-n is --new; -p and --proto are --prototypes; -l is --local)
#   pp --prototypes <name>             open the prototype <name>, even when a project shares the name
function pp() {
    local script=${WHC_DOTFILES_DIR:-$HOME/dotfiles}/walker/tmux-projects.py
    local usage='usage: pp [--refresh [project] | -n|--new [-p|--proto|--prototypes] [-l|--local] name | -p|--proto|--prototypes name | project]'
    if (( $# == 0 )); then
        python3 "$script" terminal-pick
    elif [[ $1 == --refresh ]]; then
        (( $# <= 2 )) || { print -u2 $usage; return 2; }
        if (( $# == 2 )); then
            python3 "$script" refresh "$2"
        else
            python3 "$script" refresh
        fi
    elif [[ $1 == (-n|--new|-p|--proto|--prototypes|-l|--local) ]]; then
        local new= prototype= local_root= name= arg
        for arg; do
            case $arg in
                -n|--new) new=1 ;;
                -p|--proto|--prototypes) prototype=--prototype ;;
                -l|--local) local_root=--local ;;
                -*) print -u2 $usage; return 2 ;;
                *) [[ -z $name ]] || { print -u2 $usage; return 2; }; name=$arg ;;
            esac
        done
        [[ -n $name ]] || { print -u2 $usage; return 2; }
        [[ -z $local_root || -n $new ]] || { print -u2 $usage; return 2; }
        if [[ -n $new ]]; then
            python3 "$script" new "$name" ${prototype:+$prototype} ${local_root:+$local_root}
        else
            python3 "$script" terminal-open "proto/${name#proto/}"
        fi
    elif (( $# == 1 )); then
        python3 "$script" terminal-open "$1"
    else
        print -u2 $usage
        return 2
    fi
}

function _pp() {
    local script=${WHC_DOTFILES_DIR:-$HOME/dotfiles}/walker/tmux-projects.py
    local -a projects
    if [[ ${words[2]} == (-n|--new|-p|--proto|--prototypes) ]]; then
        # A new name is free text; only the other flag can be completed.
        (( ${words[(I)(-p|--proto|--prototypes)]} )) || compadd -- --prototypes
        if (( ${words[(I)(-n|--new)]} )); then
            (( ${words[(I)(-l|--local)]} )) || compadd -- --local
            return
        fi
        compadd -- --new
        # pp -p <name> opens an existing prototype.
        projects=("${(@f)$(python3 "$script" complete 2>/dev/null)}")
        compadd -- ${${(M)projects:#proto/*}#proto/}
        return
    fi
    projects=("${(@f)$(python3 "$script" complete 2>/dev/null)}")
    if (( CURRENT == 2 )); then
        compadd -- --refresh --new
        _describe 'project' projects
    elif [[ ${words[2]} == --refresh ]]; then
        _describe 'project' projects
    fi
}

compdef _pp pp
