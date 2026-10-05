#!/bin/sh
# Leave Hyprland cleanly: hyprshutdown when installed, otherwise ask the compositor to exit.
# Used by the Super+M bind and the Walker session menu so both behave the same.
if command -v hyprshutdown >/dev/null 2>&1; then
    exec hyprshutdown
fi
exec hyprctl dispatch 'hl.dsp.exit()'
