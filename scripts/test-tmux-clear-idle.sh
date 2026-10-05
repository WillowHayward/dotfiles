#!/usr/bin/env bash
# Checks tmux-clear-idle.sh on a private tmux server: idle shells are cleared, a pane running a
# program and a pane in the alternate screen are not. Run by `just test`.
set -euo pipefail
command -v tmux >/dev/null 2>&1 || { echo "tmux not installed; skipping"; exit 0; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
socket=whc-clear-test-$$
tm() { tmux -L "$socket" "$@"; }
trap 'tm kill-server 2>/dev/null || true' EXIT

shell="bash --norc --noprofile -i"
tm -f /dev/null new-session -d -x 120 -y 40 -s t "$shell"        # idle shell 1
tm split-window -h -t t "sleep 300"                               # a running program
tm split-window -v -t t:0.0 "$shell"                              # idle shell 2
alternate=$(tm split-window -v -P -F "#{pane_id}" -t t:0.1 "$shell") # a shell in the alternate screen
sleep 1
tm send-keys -t "$alternate" "printf '\\033[?1049h'" Enter
for pane in $(tm list-panes -t t -F '#{pane_id}'); do tm send-keys -t "$pane" "echo MARK" Enter; done
sleep 1
output=$(TMUX=$(tm display-message -p '#{socket_path},0,0') "$root/scripts/tmux-clear-idle.sh")
sleep 1
[[ $output == "Cleared 2 idle pane(s)" ]] || { echo "FAIL: expected two idle panes cleared, got: $output" >&2; exit 1; }
cleared=0
for pane in $(tm list-panes -t t -F '#{pane_id}'); do
    tm capture-pane -p -t "$pane" | grep -q MARK || cleared=$((cleared + 1))
done
[[ $cleared == 2 ]] || { echo "FAIL: $cleared panes lost their output; expected 2" >&2; exit 1; }
echo "tmux clear-idle tests passed."
