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

# Install the tmux project picker integration.
tmux-projects:
    bash scripts/setup-tmux-projects.sh

# Check justfiles and shell-script syntax.
check:
    just --fmt --check
    @find scripts setup -type f -name '*.sh' -print0 | xargs -0 bash -n

# Run the isolated setup test suite.
test: check
    bash setup/test.sh
