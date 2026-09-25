#!/bin/sh
# Prefer brightnessctl; use logind when it is not installed.
set -eu
case "${1:-}" in
    up) adjustment=5%+; direction=1 ;;
    down) adjustment=5%-; direction=-1 ;;
    *) exit 2 ;;
esac
if command -v brightnessctl >/dev/null 2>&1; then
    exec brightnessctl -e4 -n2 set "$adjustment"
fi
for device_path in /sys/class/backlight/*; do
    [ -r "$device_path/max_brightness" ] || continue
    read -r maximum < "$device_path/max_brightness"
    read -r current < "$device_path/brightness"
    step=$(( (maximum + 19) / 20 ))
    minimum=$(( (maximum + 49) / 50 ))
    target=$(( current + direction * step ))
    [ "$target" -ge "$minimum" ] || target=$minimum
    [ "$target" -le "$maximum" ] || target=$maximum
    exec busctl --system call org.freedesktop.login1 \
        /org/freedesktop/login1/session/auto org.freedesktop.login1.Session \
        SetBrightness ssu backlight "${device_path##*/}" "$target"
done
notify-send 'Brightness' 'No controllable backlight was found.'
exit 1
