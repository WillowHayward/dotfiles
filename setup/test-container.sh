#!/usr/bin/env bash
# Run a profile's real setup in a throw-away Debian container and check the result.
# Needs docker and network access (it installs packages and clones plugins).
# Usage: setup/test-container.sh remote|work [image]
set -euo pipefail

profile=${1:-}
image=${2:-debian:stable-slim}
case "$profile" in
    remote|work) ;;
    *)
        printf 'Usage: %s remote|work [image]\n' "$0" >&2
        exit 2
        ;;
esac
command -v docker >/dev/null 2>&1 || { printf 'docker is required.\n' >&2; exit 1; }
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

docker run --rm -i -v "$repo:/src:ro" -e "PROFILE=$profile" -e WHC_AI=true -e TERM=xterm-256color "$image" bash -s <<'CONTAINER'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
ok() { printf 'ok: %s\n' "$*"; }

apt-get update -qq >/dev/null
apt-get install -y -qq sudo ca-certificates >/dev/null
cp -r /src /root/dotfiles
cd /root/dotfiles
printf 'WHC_PROFILE="%s"\nWHC_DEVICE="test"\n' "$PROFILE" > /etc/environment

if [[ $PROFILE == work ]]; then
    bash setup/setup.sh all >/tmp/setup.log 2>&1 || { tail -30 /tmp/setup.log; fail "setup all"; }
else
    for task in packages links shell tmux; do
        bash setup/setup.sh "$task" >"/tmp/$task.log" 2>&1 || { tail -30 "/tmp/$task.log"; fail "setup $task"; }
    done
fi
ok "setup completed"
export PATH="$HOME/.local/bin:$HOME/.local/share/fnm:$PATH"

for command in zsh tmux git vim fzf rg less; do
    command -v "$command" >/dev/null || fail "$command is missing"
done
ok "core commands installed"

if [[ $PROFILE == work ]]; then
    for command in nvim fnm node lazygit gh; do
        command -v "$command" >/dev/null || fail "$command is missing"
    done
    nvim --version | head -1 | grep -qE 'NVIM v0\.(1[1-9]|[2-9][0-9])' || fail "Neovim is older than 0.11"
    ok "developer tools installed ($(nvim --version | head -1))"
else
    for command in nvim fnm node lazygit; do
        ! command -v "$command" >/dev/null || fail "remote must not install $command"
    done
    ok "no developer tools on remote"
fi

# An interactive zsh must load the profile, plugins and prompt without errors.
cat > /tmp/probe.zsh <<'PROBE'
print -r -- "PROFILE=$WHC_PROFILE DEV=${WHC_DEV:-} P10K=$+functions[p10k] SUGGEST=$+functions[_zsh_autosuggest_start]"
editor=$(git var GIT_EDITOR)
print -r -- "EDITOR_OK=$(command -v ${editor%% *} >/dev/null && echo yes || echo no) ($editor)"
PROBE
output=$(script -qec "zsh -i /tmp/probe.zsh" /dev/null </dev/null 2>&1 | tr -d "\r" || true)
grep -q "PROFILE=$PROFILE" <<<"$output" || { printf '%s\n' "$output"; fail "zsh did not load profile $PROFILE"; }
grep -q 'P10K=1 SUGGEST=1' <<<"$output" || { printf '%s\n' "$output"; fail "zsh plugins did not load"; }
grep -q 'EDITOR_OK=yes' <<<"$output" || { printf '%s\n' "$output"; fail "git editor is not installed"; }
grep -qiE 'command not found|no such file|parse error|error' <<<"$output" && { printf '%s\n' "$output"; fail "zsh printed errors"; }
ok "zsh loads the $PROFILE profile; git editor resolves"

# Git: https stays https on remote, is rewritten to SSH on work.
rewrites=$(git config --get-all url.git@github.com:.insteadof || true)
if [[ $PROFILE == remote ]]; then
    [[ -z $rewrites ]] || fail "remote must not rewrite github URLs"
else
    [[ $rewrites == https://github.com/ ]] || fail "work should rewrite github URLs to SSH"
fi
ok "git profile config"
if [[ $PROFILE == work ]]; then
    # First start: lazy.nvim bootstraps every plugin over https, then Mason's
    # registry loads. Any plugin that fails to configure shows up here.
    echo 'local x = 1' > /tmp/x.lua
    WHC_PROFILE=work timeout 300 nvim --headless /tmp/x.lua \
        "+lua vim.defer_fn(function() vim.cmd('qa!') end, 150000)" >/tmp/nvim.out 2>&1 || true
    if sed 's/\x1b\[[0-9;]*m//g' /tmp/nvim.out | tr '\r' '\n' | grep -E 'Failed to run|^E[0-9]+:|Error executing'; then
        fail "Neovim reported errors on first start"
    fi
    ok "Neovim starts cleanly on first run"
fi
printf 'All checks passed for %s.\n' "$PROFILE"
CONTAINER
