#!/usr/bin/env bash
# Build the official plugin version pinned for the installed Hyprland headers.
set -euo pipefail
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
curl -fsSL https://raw.githubusercontent.com/hyprwm/hyprland-plugins/main/hyprpm.toml -o "$build_dir/hyprpm.toml"
plugin_commit=$(
    python3 - "$build_dir/hyprpm.toml" <<'PYCODE'
import pathlib, re, sys, tomllib
headers = pathlib.Path('/usr/include/hyprland/src/version.h').read_text()
commit = re.search(r'#define GIT_COMMIT_HASH\s+"([a-f0-9]+)"', headers).group(1)
pins = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())['repository']['commit_pins']
for hyprland, plugin in pins:
    if hyprland == commit:
        if not re.fullmatch(r'[a-f0-9]{40}', plugin):
            sys.exit('Invalid plugin commit')
        print(plugin)
        break
else:
    sys.exit('No official plugin pin for these Hyprland headers; not building an incompatible plugin.')
PYCODE
)
curl -fsSL "https://github.com/hyprwm/hyprland-plugins/archive/$plugin_commit.tar.gz" -o "$build_dir/source.tar.gz"
tar -xzf "$build_dir/source.tar.gz" -C "$build_dir"
make -C "$build_dir/hyprland-plugins-$plugin_commit/hyprbars"
install -Dm755 "$build_dir/hyprland-plugins-$plugin_commit/hyprbars/hyprbars.so" "$HOME/.local/lib/hyprland/hyprbars.so.new"
mv "$HOME/.local/lib/hyprland/hyprbars.so.new" "$HOME/.local/lib/hyprland/hyprbars.so"
printf '%s\n' 'Hyprbars installed. Reload Hyprland (or log in again after a Hyprland upgrade).'
