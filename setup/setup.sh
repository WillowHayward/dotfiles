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
  init-system  Set WHC_PROFILE and WHC_DEVICE in /etc/environment ($PREFIX/etc/environment in Termux)
  packages [--list|--diff]  Install the profile's package baseline (--list prints it;
               --diff shows what is installed but not in the manifest)
  links [--relink|--adopt]  Link profile-appropriate dotfiles (--relink: replace wrong symlinks;
               --adopt: also move conflicting real files to a backup)
  shell        Configure zsh and Antidote
  nvim         Install Neovim 0.11+ and link its configuration
  tmux         Install and configure tmux and TPM
  node         Install fnm and the latest LTS Node.js (home, work and mobile)
  python       Install uv (home, work and mobile)
  ssh          Add the shared ssh defaults and config.d to ~/.ssh/config
  bash         Source the tiny bashrc from ~/.bashrc
  docker       Install Docker Engine from Docker's apt repository (remote)
  wsl          Install the WSL config templates (work, WSL only)
  harden       Harden sshd, updates and the firewall (remote only; asks first)
  doctor       Report missing tools, wrong links and drift for this profile
  termux       Termux settings, font, widget shortcuts, boot script and sshd (Termux only)
  desktop      Install and link the Hyprland desktop (home only)
  manual-lock  Configure greetd, hyprlock, hypridle, and logind (home only)
  all          Run every task the profile includes
EOF
}

task=${1:-}
# Optional flag: links --relink|--adopt, packages --list|--diff.
if [[ $# -eq 2 && $task == links && ($2 == --relink || $2 == --adopt) ]]; then
    export WHC_LINK_MODE=${2#--}
    set -- "$task"
elif [[ $# -eq 2 && $task == packages && ($2 == --list || $2 == --diff) ]]; then
    export WHC_PACKAGES_MODE=${2#--}
    set -- "$task"
fi
if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

case "$task" in
init-system)
    task_init_system
    ;;
packages | links | shell | nvim | tmux | node | python | ssh | bash | docker | wsl | harden | doctor | termux | desktop | manual-lock | all)
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
