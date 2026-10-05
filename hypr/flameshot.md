# Flameshot on mixed-scale Hyprland monitors

Print Screen runs `flameshot.sh`: capture the focused output at native resolution,
then select/crop/annotate and copy using the usual Flameshot editor.

The packaged Flameshot 14.0.0 captures a composite desktop through the portal,
then crops using a bounding box that includes (0,0) and rescales to Qt's screen
DPR. This produces a shifted image with this monitor layout (whose left edge is
x=160), and 3200x1800 instead of 2560x1440 on the 160% DP-1 output. The application
windows themselves remained in place during reproduction.

`flameshot-native-output.patch` adds an opt-in capture path. It matches Qt screens
by the Hyprland output name, calls `grim -o OUTPUT -s SCALE -t png -`, and sets the
pixmap DPR from the actual pixels/logical width. It never rescales the captured
pixels. Without the two FLAMESHOT_NATIVE_* variables, upstream behavior remains.
The launcher clears inherited Qt scaling overrides and prevents repeat overlays.

Build/install with `~/.config/hypr/install-flameshot.sh`. Dependencies are listed
in that script; CMake also fetches upstream's pinned QtColorWidgets and
KDSingleApplication dependencies. The source archive is version/checksum pinned.
The binary lives at `~/.local/lib/flameshot-hyprland/flameshot`; `/usr/bin/flameshot`
and its tray daemon remain installed. Rebuild after incompatible Qt library
updates. Other launchers using `/usr/bin/flameshot` retain upstream behavior.

To revert, change `takeScreenshot` in `utils.lua` back to invoking the system
`flameshot screen --number ... --clipboard --edit` and reload Hyprland. No monitor
layout or scaling changes are required.

References:
- https://github.com/flameshot-org/flameshot/blob/v14.0.0/src/utils/screengrabber.cpp
- https://github.com/flameshot-org/flameshot/issues/4818
