# fzf: fd (or Debian's fdfind) for file lists when present, Dracula colours.
# These are read when fzf's key bindings run, so set them first.
whc_fd=${commands[fd]:-${commands[fdfind]:-}}
if [[ -n $whc_fd ]]; then
    export FZF_DEFAULT_COMMAND="${whc_fd:t} --type f --hidden --exclude .git"
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
    export FZF_ALT_C_COMMAND="${whc_fd:t} --type d --hidden --exclude .git"
fi
unset whc_fd
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9,info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

# fzf key bindings (Ctrl-R, Ctrl-T, Alt-C). `fzf --zsh` needs fzf 0.48+; older
# distro packages (e.g. Debian bookworm) ship the scripts instead.
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

# Atuin takes over Ctrl-R (fuzzy, synced history) when installed; the Up arrow keeps its
# normal behaviour. Sync needs an account (`atuin register` / `atuin login`), which is
# per user and never stored here.
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

# zoxide: `z <partial>` jumps to a frequently used directory, `zi` picks with fzf.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
