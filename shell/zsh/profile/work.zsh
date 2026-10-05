# Configuration particular to my workplace (WSL, Debian).
# Sourced last, only when WHC_PROFILE=work. Keep anything private in
# profile/work.local.zsh, which is not tracked.

# TaskWarrior - Assumes context "work" set to "project:work" exists
(( $+commands[task] )) && task context work
alias taw='task add project:work'

# WSL: open URLs and files with the Windows default handlers when wslu is installed.
if [[ -n $WSL_DISTRO_NAME ]]; then
    (( $+commands[wslview] )) && export BROWSER=wslview
    (( $+commands[wslview] )) && alias open='wslview'
fi

[[ -r ${${(%):-%x}:A:h}/work.local.zsh ]] && source "${${(%):-%x}:A:h}/work.local.zsh"
