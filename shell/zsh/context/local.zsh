# Sourced only for local (non-SSH) shells: every new terminal attaches to the
# general tmux session. Keep this last in .zshrc, because it replaces the shell.

if [[ -z "$TMUX" && "$WHC_AI" != true ]] && (( $+commands[tmux] )); then
    exec tmux new-session -A -s general
fi
