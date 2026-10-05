# fnm replaces nvm. Keep initialization before local.zsh attaches to tmux.
path=("${FNM_DIR:-$HOME/.local/share/fnm}" $path)
typeset -U path
if (( $+commands[fnm] )); then
    eval "$(fnm env --use-on-cd --shell zsh --version-file-strategy recursive)"
fi
