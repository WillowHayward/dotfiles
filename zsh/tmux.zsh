# Launch tmux
[ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
cd $HOME # TODO: Make this cd to the last directory
