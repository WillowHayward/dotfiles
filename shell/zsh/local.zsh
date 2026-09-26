# This file is for configuration particular to local (non-ssh) configurations, and will not always be committed
# It will be loaded nearly last, and only if WHC_LOCAL is set

if [[ -z "$TMUX" && "$WHC_AI" != true ]]; then
    exec tmux new-session -A -s general
fi
