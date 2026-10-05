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

# Check justfiles, shell, zsh and Python syntax.
check:
    just --fmt --check
    @find scripts setup hypr -type f -name '*.sh' -print0 | xargs -0 bash -n
    @find shell -type f \( -name '.zshrc' -o -name '*.zsh' \) -print0 | xargs -0 -n1 zsh -n
    @python3 -c "import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" walker/tmux-projects.py nvim/bin/godot-editor nvim/bin/godot-session

# Run the setup and project-picker test suites.
test: check
    bash setup/test.sh
    python3 -B -m unittest discover -s walker -p 'test_*.py'

# Run a profile's real setup in a throw-away Debian container (needs docker and network).
test-container profile:
    bash setup/test-container.sh {{ profile }}
