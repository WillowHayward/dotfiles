#!/usr/bin/env bash
# Native-resolution active-output capture with Flameshot's existing editor.
# Usage: flameshot.sh [clipboard|file]   (file saves under ~/Pictures/Screenshots)
set -euo pipefail
mode=${1:-clipboard}
binary="$HOME/.local/lib/flameshot-hyprland/flameshot"
if [[ ! -x "$binary" ]]; then
    notify-send 'Flameshot setup required' 'Run ~/.config/hypr/install-flameshot.sh'
    exit 1
fi
# Ignore key repeats while an editor is already open.
exec 9>"${XDG_RUNTIME_DIR:?}/flameshot-native.lock"
flock -n 9 || exit 0
monitor=$(hyprctl -j monitors | jq -er '.[] | select(.focused) | [.name, .scale] | @tsv')
IFS=$'\t' read -r output scale <<<"$monitor"
# QScreen indices need not match Hyprland IDs. The patch selects by output name.
case "$mode" in
clipboard) destination=(--clipboard) ;;
file)
    directory=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots
    mkdir -p -- "$directory"
    destination=(--path "$directory")
    ;;
*)
    printf 'Usage: %s [clipboard|file]\n' "$0" >&2
    exit 2
    ;;
esac
exec env -u QT_AUTO_SCREEN_SCALE_FACTOR -u QT_SCREEN_SCALE_FACTORS -u QT_SCALE_FACTOR \
    QT_QPA_PLATFORM=wayland FLAMESHOT_NATIVE_OUTPUT="$output" FLAMESHOT_NATIVE_SCALE="$scale" \
    "$binary" screen --number 0 "${destination[@]}" --edit
