set shell := ["bash", "-cu"]

# Profile-aware machine setup.
mod setup

# List the available recipes.
default:
    @just --list

# Link profile-appropriate dotfiles into the home directory.
link:
    @just setup links

# List the helper scripts that can be run with `just run`.
scripts:
    @for script in scripts/*.sh; do basename "$script" .sh; done | sort

# Run a helper script by basename, passing through any additional arguments.
run script *args:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ script }}" in
        */*|.*|'')
            printf 'Script must be a basename from scripts/: %s\n' "{{ script }}" >&2
            exit 2
            ;;
    esac
    script_path="scripts/{{ script }}.sh"
    if [[ ! -f "$script_path" ]]; then
        printf 'Unknown script: %s\n' "{{ script }}" >&2
        printf 'Run `just scripts` to list available scripts.\n' >&2
        exit 2
    fi
    bash "$script_path" {{ args }}

# Report missing tools, wrong links and drift for this machine's profile.
doctor:
    @just setup doctor

# Compare every pinned version and plugin commit with upstream (--fail exits 1 when behind).
updates *flag:
    bash scripts/check-updates.sh {{ flag }}

# Pull the repo, update TPM plugins, move fnm to the latest LTS, sync Neovim plugins, then report pins.
update:
    git pull --rebase --autostash
    if [ -x ~/.tmux/plugins/tpm/bin/update_plugins ]; then ~/.tmux/plugins/tpm/bin/update_plugins all; fi
    if command -v fnm >/dev/null 2>&1; then fnm install --lts && fnm default lts-latest; fi
    just nvim-update
    just updates

# Sync Neovim plugins, smoke-test the config and show how lazy-lock.json changed (commit it deliberately).
nvim-update:
    nvim --headless "+Lazy! sync" +qa
    bash scripts/nvim-smoke.sh
    git --no-pager diff --stat -- nvim/lazy-lock.json

# Forget the cached zsh plugin bundles and completion dump; the next shell rebuilds them.
zsh-refresh:
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/whc/zsh_plugins.* "${XDG_CACHE_HOME:-$HOME/.cache}"/whc/zcompdump*
    @echo "Cleared. Open a new shell (or run: exec zsh) to rebuild."

# Print the live keybinds as Markdown (sections: hypr, tmux, nvim; default all).
keybinds *sections:
    python3 scripts/keybinds.py {{ sections }}

# Format Lua (stylua) and shell (shfmt) with the repo's settings; formatters that are missing are skipped.
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    stylua=$(command -v stylua || true)
    [[ -n $stylua ]] || stylua=$(ls ~/.local/share/nvim/mason/bin/stylua 2>/dev/null || true)
    if [[ -n $stylua ]]; then "$stylua" nvim hypr swayimg; else echo "stylua not found; skipping Lua"; fi
    shfmt=$(command -v shfmt || ls ~/.local/share/nvim/mason/bin/shfmt 2>/dev/null || true)
    if [[ -n $shfmt ]]; then
        find scripts setup hypr -type f -name '*.sh' -print0 | xargs -0 "$shfmt" -w
    else
        echo "shfmt not found; skipping shell"
    fi

# Check justfiles, shell, zsh and Python syntax.
check:
    just --fmt --check
    @find scripts setup hypr -type f -name '*.sh' -print0 | xargs -0 bash -n
    @if command -v shellcheck >/dev/null 2>&1; then find scripts setup hypr -type f -name '*.sh' -print0 | xargs -0 shellcheck -x; else echo 'shellcheck not installed; skipping'; fi
    @python3 scripts/check-recipe-docs.py
    @find shell -type f \( -name '.zshrc' -o -name '*.zsh' \) -print0 | xargs -0 -n1 zsh -n
    @python3 -c "import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" walker/tmux-projects.py nvim/bin/godot-editor nvim/bin/godot-session

# Run the setup and project-picker test suites.
test: check
    bash setup/test.sh
    zsh shell/test.zsh
    nvim -l hypr/test.lua
    bash scripts/test-tmux-clear-idle.sh
    python3 -B -m unittest discover -s walker -p 'test_*.py'

# Run a profile's real setup in a throw-away Debian container (needs docker and network).
test-container profile:
    bash setup/test-container.sh {{ profile }}
