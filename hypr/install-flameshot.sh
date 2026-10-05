#!/usr/bin/env bash
# Local, opt-in Flameshot 14 fix; does not replace the distribution package.
# Build dependencies (Arch): base-devel cmake git curl qt6-base qt6-tools qt6-svg.
# Runtime: flameshot (data/daemon), grim, jq, util-linux, libnotify.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
curl -fL --retry 3 https://github.com/flameshot-org/flameshot/archive/refs/tags/v14.0.0.tar.gz -o "$build_dir/source.tar.gz"
printf '%s  %s\n' 810c399f3b9fbfd72e24e61417ede24243925f9c0d03040a8aba0d4866676d93 "$build_dir/source.tar.gz" | sha256sum -c -
tar -xzf "$build_dir/source.tar.gz" -C "$build_dir"
source_dir="$build_dir/flameshot-14.0.0"
patch -d "$source_dir" -p1 < "$script_dir/flameshot-native-output.patch"
cmake -S "$source_dir" -B "$build_dir/build" -DCMAKE_BUILD_TYPE=Release \
    -DDISABLE_UPDATE_CHECKER=ON -DUSE_LAUNCHER_ABSOLUTE_PATH=OFF
cmake --build "$build_dir/build" --parallel "${CMAKE_BUILD_PARALLEL_LEVEL:-4}"
install -Dm755 "$build_dir/build/src/flameshot" "$HOME/.local/lib/flameshot-hyprland/flameshot.new"
mv "$HOME/.local/lib/flameshot-hyprland/flameshot.new" "$HOME/.local/lib/flameshot-hyprland/flameshot"
printf '%s\n' 'Installed the native-output Flameshot build used by Print Screen.'
