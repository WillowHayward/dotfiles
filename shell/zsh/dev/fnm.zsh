# fnm replaces nvm.
path=("${FNM_DIR:-$HOME/.local/share/fnm}" $path)
typeset -gU path
if (( $+commands[fnm] )); then
    eval "$(fnm env --use-on-cd --shell zsh --version-file-strategy recursive)"
fi
