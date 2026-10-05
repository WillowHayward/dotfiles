#!/bin/bash
# Keep AI shells away from interactive zsh setup and its shared history.
set -e
export WHC_AI=true
export SHELL=/bin/bash
root=$(cd -- "${WHC_PROJECT_ROOT:-$PWD}" && pwd -P)
key=$(printf '%s' "$root" | sha256sum)
key=${key%% *}
history_dir="${XDG_STATE_HOME:-$HOME/.local/state}/whc-ai"
mkdir -p -- "$history_dir"
chmod 700 -- "$history_dir"
export HISTFILE="$history_dir/$key.bash_history"
export HISTSIZE=10000 HISTFILESIZE=20000
dotfiles=${WHC_DOTFILES_DIR:-$HOME/dotfiles}
export BASH_ENV="$dotfiles/shell/ai.bashrc"
source "$dotfiles/shell/node.bash"
unset WHC_PROJECT_ROOT
exec "$@"
