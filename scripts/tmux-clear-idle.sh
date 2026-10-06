#!/usr/bin/env bash
# Clear the panes of the current tmux window that are just waiting at a shell prompt: the
# screen is cleared (Ctrl-L, so a half-typed command is kept) and the scrollback dropped.
# Panes running anything else (Neovim, an agent, a dev server, ssh, a pager) are left alone.
# Bound to `prefix C` in shell/.tmux.conf.
set -euo pipefail

window=${1:-$(tmux display-message -p '#{window_id}')}
cleared=0
while IFS=$'\t' read -r pane command alternate; do
    case "$command" in
    zsh | bash | sh | dash | fish) ;;
    *) continue ;;
    esac
    # A full-screen program inside a shell (alternate screen) is not "waiting".
    [[ $alternate == 0 ]] || continue
    tmux send-keys -t "$pane" C-l
    tmux clear-history -t "$pane"
    cleared=$((cleared + 1))
done < <(tmux list-panes -t "$window" -F '#{pane_id}'$'\t''#{pane_current_command}'$'\t''#{alternate_on}')
message="Cleared $cleared idle pane(s)"
echo "$message"
tmux display-message "$message"
