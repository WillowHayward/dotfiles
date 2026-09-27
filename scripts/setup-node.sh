#!/bin/bash
set -euo pipefail
export PATH="${FNM_DIR:-$HOME/.local/share/fnm}:$PATH"
if ! command -v fnm >/dev/null 2>&1; then
    installer=$(mktemp)
    trap 'rm -f -- "$installer"' EXIT
    curl -fsSL https://fnm.vercel.app/install -o "$installer"
    bash "$installer" --skip-shell
fi
eval "$(fnm env --shell bash)"
fnm install --lts
fnm default lts-latest
fnm use default
fnm --version
node --version
npm --version
