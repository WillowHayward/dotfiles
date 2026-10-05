#!/bin/sh
# Super + volume controls the focused output; laptop brightness keys use internal.
set -eu
case "${1:-}" in
up)
    adjustment=5%+
    direction=1
    relative=+
    ;;
down)
    adjustment=5%-
    direction=-1
    relative=-
    ;;
*) exit 2 ;;
esac

fail() {
    printf '%s\n' "$1" >&2
    notify-send -h string:x-canonical-private-synchronous:brightness 'Brightness' "$1" || :
    exit 1
}

case "${2:-active}" in
active)
    monitor=$(hyprctl monitors -j | jq -er '.[] | select(.focused == true) | .name') ||
        fail 'Could not identify the active monitor.'
    ;;
internal) monitor=eDP-internal ;;
*) exit 2 ;;
esac

case "$monitor" in
eDP-* | LVDS-* | DSI-*) ;;
*)
    command -v ddcutil >/dev/null 2>&1 || fail 'Install ddcutil to control external monitors.'
    # Resolve the connector on every invocation: bus numbers can change on hotplug.
    bus=
    for connector in /sys/class/drm/card*-"$monitor"; do
        [ -r "$connector/status" ] || continue
        [ "$(cat "$connector/status")" = connected ] || continue
        [ -e "$connector/ddc" ] || continue
        [ -z "$bus" ] || fail "Ambiguous DDC connection for $monitor."
        bus=$(basename "$(readlink -f "$connector/ddc")")
    done
    case "$bus" in
    i2c-*) bus=${bus#i2c-} ;;
    *) fail "$monitor has no accessible DDC connection." ;;
    esac
    case "$bus" in '' | *[!0-9]*) fail "Invalid DDC bus for $monitor." ;; esac
    [ -r "/dev/i2c-$bus" ] && [ -w "/dev/i2c-$bus" ] ||
        fail "Cannot access $monitor DDC bus; check i2c-dev and ddcutil udev permissions."
    # Serialize knob events so read/modify/write operations cannot race.
    exec 9>"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/brightness-i2c-$bus.lock"
    flock -w 2 9 || exit 0
    # VCP 0x10 is hardware brightness. ddcutil clamps relative changes to its limits.
    ddcutil --bus "$bus" setvcp 10 "$relative" 5 ||
        fail "$monitor did not accept brightness control. Check DDC/CI in its menu."
    exit 0
    ;;
esac

# Internal panel: preserve the existing brightnessctl/logind behavior.
if command -v brightnessctl >/dev/null 2>&1; then
    exec brightnessctl --class=backlight -e4 -n2 set "$adjustment"
fi
for device_path in /sys/class/backlight/*; do
    [ -r "$device_path/max_brightness" ] || continue
    read -r maximum <"$device_path/max_brightness"
    read -r current <"$device_path/brightness"
    step=$(((maximum + 19) / 20))
    minimum=$(((maximum + 49) / 50))
    target=$((current + direction * step))
    [ "$target" -ge "$minimum" ] || target=$minimum
    [ "$target" -le "$maximum" ] || target=$maximum
    exec busctl --system call org.freedesktop.login1 \
        /org/freedesktop/login1/session/auto org.freedesktop.login1.Session \
        SetBrightness ssu backlight "${device_path##*/}" "$target"
done
fail 'No controllable internal backlight was found.'
