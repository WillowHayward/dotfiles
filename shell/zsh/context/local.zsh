# Sourced only for local (non-SSH) shells: every new terminal attaches to the
# general tmux session. It replaces the shell, so .zshrc sources it right after env and path.

if [[ -z "$TMUX" && "$WHC_AI" != true ]] && (( $+commands[tmux] )); then
    exec tmux new-session -A -s general
fi
