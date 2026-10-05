# Bash fallback for machines where zsh is unavailable. Zsh is the primary shell
# (see .zshrc); this is not linked by `just setup`, so link it by hand if needed.
[[ $- == *i* ]] || return

# Set vi/vim/nvim settings
if command -v nvim >/dev/null 2>&1; then VISUAL=nvim; elif command -v vim >/dev/null 2>&1; then VISUAL=vim; else VISUAL=vi; fi
export VISUAL
export EDITOR="$VISUAL"
set -o vi

# Node (fnm replaced nvm)
[ -r "$HOME/dotfiles/shell/node.bash" ] && source "$HOME/dotfiles/shell/node.bash"

# Launch tmux for local shells only
if [ -z "$TMUX" ] && [ -z "$SSH_CONNECTION" ] && [ "${WHC_AI:-}" != true ] && command -v tmux >/dev/null 2>&1; then
    exec tmux new-session -A -s general
fi
