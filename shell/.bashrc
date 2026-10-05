# Very small bash fallback for hosts where zsh is not (yet) the login shell. `just setup bash`
# appends a line to ~/.bashrc that sources this file after the distribution's own setup.
[[ $- == *i* ]] || return 0

# Editor and vi keys, matching zsh.
if command -v nvim >/dev/null 2>&1; then VISUAL=nvim; elif command -v vim >/dev/null 2>&1; then VISUAL=vim; else VISUAL=vi; fi
export VISUAL EDITOR=$VISUAL
set -o vi

# Remote machines and SSH sessions: a red [device] prefix, as in the zsh prompt.
whc_device=${WHC_DEVICE:-}
whc_profile=${WHC_PROFILE:-}
if [[ -r /etc/environment ]]; then
    [[ -n $whc_device ]] || whc_device=$(sed -n 's/^WHC_DEVICE="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /etc/environment | tail -n1)
    [[ -n $whc_profile ]] || whc_profile=$(sed -n 's/^WHC_PROFILE="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /etc/environment | tail -n1)
fi
if [[ $whc_profile == remote || -n ${SSH_CONNECTION:-} ]]; then
    PS1="\[\e[1;31m\][${whc_device:-\h}]\[\e[0m\] ${PS1:-\u@\h:\w\$ }"
fi
unset whc_device whc_profile
