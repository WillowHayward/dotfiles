# Set vi/vim/nvim settings
export VISUAL=nvim
export EDITOR="$VISUAL"
set -o vi
setxkbmap -option caps:swapescape # Swap caps and escape

# Load NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Launch tmux
[ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
