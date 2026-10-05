# Environment variables - To be run at the start of zsh launch
# WHC_ prefix for Willow Hayward Code stuff
export WHC_DOTFILES_DIR="$HOME/dotfiles"
if [[ -f "$WHC_DOTFILES_DIR/.env" ]]; then # Global environment variables not for committing
    set -o allexport
    source "$WHC_DOTFILES_DIR/.env"
    set +o allexport
fi

# Machine identity is managed by `just setup init-system`. Read it again after
# .env so a stale local file cannot override the system-wide values.
unset WHC_PROFILE WHC_DEVICE
whc_environment_file=${WHC_ENVIRONMENT_FILE:-/etc/environment}
if [[ -r $whc_environment_file ]]; then
    whc_system_profile=$(awk -F= '$1 == "WHC_PROFILE" { value=$0; sub(/^[^=]*=/, "", value) } END { print value }' "$whc_environment_file")
    whc_system_device=$(awk -F= '$1 == "WHC_DEVICE" { value=$0; sub(/^[^=]*=/, "", value) } END { print value }' "$whc_environment_file")
    whc_system_profile=${whc_system_profile#\"}
    whc_system_profile=${whc_system_profile%\"}
    whc_system_device=${whc_system_device#\"}
    whc_system_device=${whc_system_device%\"}
    if [[ -n $whc_system_profile ]]; then
        export WHC_PROFILE=$whc_system_profile
    fi
    if [[ -n $whc_system_device ]]; then
        export WHC_DEVICE=$whc_system_device
    fi
    unset whc_system_profile whc_system_device
fi
unset whc_environment_file

# An unknown or missing profile gets the lightest configuration.
case ${WHC_PROFILE:-} in
    home|work|remote) ;;
    *)
        [[ -o interactive ]] && print -u2 "WHC_PROFILE is not set in /etc/environment; using 'remote'. Run 'just setup init-system'."
        export WHC_PROFILE=remote
        ;;
esac

# Profile flags (exclusive) and capability flags (what the profile includes).
unset WHC_HOME WHC_WORK WHC_LOCAL WHC_REMOTE WHC_DEV WHC_DESKTOP
case $WHC_PROFILE in
    home) export WHC_HOME=true WHC_DEV=true WHC_DESKTOP=true ;;
    work) export WHC_WORK=true WHC_DEV=true ;;
    remote) export WHC_REMOTE=true ;;
esac

if [[ -n "$SSH_CONNECTION" ]]; then
    # Connection context is independent from the machine profile.
    export WHC_REMOTE=true
else
    export WHC_LOCAL=true
fi

export WHC_PROJECTS_DIR="$HOME/projects"

# Servers do not always have Neovim; never leave EDITOR pointing at a missing binary.
if (( $+commands[nvim] )); then
    export VISUAL=nvim
elif (( $+commands[vim] )); then
    export VISUAL=vim
else
    export VISUAL=vi
fi
export EDITOR="$VISUAL"

# Oh My Zsh libraries are loaded by Antidote from its cache, not from ~/.oh-my-zsh.
export ZSH="$HOME/.cache/antidote/github.com/ohmyzsh/ohmyzsh"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"

export ANTIDOTE_DIR=${ZDOTDIR:-~}/.antidote
