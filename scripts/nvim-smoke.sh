#!/usr/bin/env bash
# Open a Lua file in headless Neovim long enough for LSP, completion and plugin configs to
# load, and fail on any plugin error. Used by `just nvim-update`.
set -euo pipefail
file=$(mktemp --suffix=.lua)
log=$(mktemp)
trap 'rm -f -- "$file" "$log"' EXIT
echo 'local x = 1' > "$file"
NVIM_EDITOR_SOCKET=$(mktemp -u) timeout 60 nvim --headless "$file" \
    "+lua vim.defer_fn(function() vim.cmd('qa!') end, ${NVIM_SMOKE_MS:-8000})" >"$log" 2>&1 || true
if sed 's/\x1b\[[0-9;]*m//g' "$log" | tr '\r' '\n' | grep -E 'Failed to run|^E[0-9]+:|Error executing|stack traceback'; then
    echo "Neovim reported errors; see above." >&2
    exit 1
fi
echo "Neovim smoke test passed."
