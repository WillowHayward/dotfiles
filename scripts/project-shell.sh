#!/bin/bash
# Neovim is a foreground child, so quitting it leaves an interactive shell.
python3 "$HOME/dotfiles/walker/tmux-projects.py" start "$TMUX_PANE" || exit
source "$HOME/dotfiles/shell/node.bash"
WHC_PROJECT_ROOT="$PWD" nvim .
exec /bin/zsh -i
