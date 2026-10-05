# Open configured projects through the same backend as Walker.
function pp() {
    local script=${WHC_DOTFILES_DIR:-$HOME/dotfiles}/walker/tmux-projects.py
    if (( $# == 0 )); then
        python3 "$script" terminal-pick
    elif [[ $1 == --refresh ]]; then
        (( $# <= 2 )) || { print -u2 'usage: pp [--refresh [project] | project]'; return 2; }
        if (( $# == 2 )); then
            python3 "$script" refresh "$2"
        else
            python3 "$script" refresh
        fi
    elif (( $# == 1 )); then
        python3 "$script" terminal-open "$1"
    else
        print -u2 'usage: pp [--refresh [project] | project]'
        return 2
    fi
}

function _pp() {
    local script=${WHC_DOTFILES_DIR:-$HOME/dotfiles}/walker/tmux-projects.py
    local -a projects
    projects=("${(@f)$(python3 "$script" complete 2>/dev/null)}")
    if (( CURRENT == 2 )); then
        compadd -- --refresh
        _describe 'project' projects
    elif [[ ${words[2]} == --refresh ]]; then
        _describe 'project' projects
    fi
}

compdef _pp pp
