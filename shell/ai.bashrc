# Used only by AI Bash processes (interactive rcfile and noninteractive BASH_ENV).
export WHC_AI=true
export SHELL=/bin/bash
source "$HOME/dotfiles/shell/node.bash"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups
shopt -s histappend
# Noninteractive AI commands get their own append-only history too.
if [[ $- == *i* ]]; then
    set -o history
    PROMPT_COMMAND='history -a'
    PS1='[ai] \w \$ '
else
    # Bash does not normally record the command passed to bash -c.
    if [[ -n "$BASH_EXECUTION_STRING" ]]; then
        history -s -- "$BASH_EXECUTION_STRING"
    fi
    trap 'history -a' EXIT
fi
