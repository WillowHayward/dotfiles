# Configuration particular to my workplace (WSL, Debian).
# Sourced last, only when WHC_PROFILE=work. Keep anything private in
# profile/work.local.zsh, which is not tracked.

# TaskWarrior - Assumes context "work" set to "project:work" exists
(( $+commands[task] )) && task context work
alias taw='task add project:work'

# Commit email for this machine, written where git/profile/work.gitconfig includes it.
# Rewritten only when WHC_WORK_EMAIL changes.
whc_work_gitconfig=${XDG_CACHE_HOME:-$HOME/.cache}/whc/gitconfig.work
if [[ -n ${WHC_WORK_EMAIL:-} ]]; then
    whc_work_gitconfig_body=$'[user]\n\temail = '$WHC_WORK_EMAIL$'\n'
    if [[ ! -f $whc_work_gitconfig || $(<$whc_work_gitconfig) != ${whc_work_gitconfig_body%$'\n'} ]]; then
        mkdir -p -- "${whc_work_gitconfig:h}"
        print -rn -- "$whc_work_gitconfig_body" >| "$whc_work_gitconfig"
    fi
    unset whc_work_gitconfig_body
fi
unset whc_work_gitconfig

# WSL: open URLs and files with the Windows default handlers when wslu is installed.
if [[ -n $WSL_DISTRO_NAME ]]; then
    (( $+commands[wslview] )) && export BROWSER=wslview
    (( $+commands[wslview] )) && alias open='wslview'
fi

[[ -r ${${(%):-%x}:A:h}/work.local.zsh ]] && source "${${(%):-%x}:A:h}/work.local.zsh"
