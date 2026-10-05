# fzf key bindings (Ctrl-R, Ctrl-T, Alt-C). `fzf --zsh` needs fzf 0.48+; older
# distro packages (e.g. Debian stable) ship the scripts instead.
if (( $+commands[fzf] )); then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    else
        for whc_fzf_dir in /usr/share/doc/fzf/examples /usr/share/fzf; do
            if [[ -r $whc_fzf_dir/key-bindings.zsh ]]; then
                source "$whc_fzf_dir/key-bindings.zsh"
                [[ -r $whc_fzf_dir/completion.zsh ]] && source "$whc_fzf_dir/completion.zsh"
                break
            fi
        done
        unset whc_fzf_dir
    fi
fi

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
