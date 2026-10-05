#!/usr/bin/env bash
set -euo pipefail

setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=lib/common.sh
source "$setup_dir/lib/common.sh"
for task_file in "$setup_dir"/tasks/*.sh; do
    # shellcheck source=/dev/null
    source "$task_file"
done

usage() {
    cat >&2 <<'EOF'
Usage: setup/setup.sh TASK

Tasks:
  init-system  Set WHC_PROFILE and WHC_DEVICE in /etc/environment
  packages     Install the profile's package baseline
  links        Link profile-appropriate dotfiles
  shell        Configure zsh and Antidote
  nvim         Install Neovim 0.11+ and link its configuration
  tmux         Install and configure tmux and TPM
  node         Install fnm and the latest LTS Node.js (home and work)
  python       Install uv (home and work)
  desktop      Install and link the Hyprland desktop (home only)
  manual-lock  Configure greetd, hyprlock, hypridle, and logind (home only)
  all          Run every task the profile includes
EOF
}

task=${1:-}
if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

case "$task" in
    init-system)
        task_init_system
        ;;
    packages|links|shell|nvim|tmux|node|python|desktop|manual-lock|all)
        load_system_identity
        validate_profile_os
        "task_${task//-/_}"
        ;;
    *)
        printf 'Unknown setup task: %s\n' "$task" >&2
        usage
        exit 2
        ;;
esac
