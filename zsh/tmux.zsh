# Launch tmux
[ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
