# Environment variables - To be run at the start of zsh launch
# WHC_ prefix for Willow Hayward Code stuff
export ZSH="$HOME/.oh-my-zsh"
export WHC_DOTFILES_DIR="$HOME/dotfiles"
if [[ -f "$WHC_DOTFILES_DIR/.env" ]]; then # Global environment variables not for committing
    set -o allexport
    source "$WHC_DOTFILES_DIR/.env"
    set +o allexport
fi

# Machine identity is managed by `just setup init-system`. Read it again after
# .env so a stale local file cannot override the system-wide values.
unset WHC_PROFILE WHC_DEVICE
if [[ -r /etc/environment ]]; then
    whc_system_profile=$(awk -F= '$1 == "WHC_PROFILE" { value=$0; sub(/^[^=]*=/, "", value) } END { print value }' /etc/environment)
    whc_system_device=$(awk -F= '$1 == "WHC_DEVICE" { value=$0; sub(/^[^=]*=/, "", value) } END { print value }' /etc/environment)
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

unset WHC_HOME WHC_WORK WHC_LOCAL WHC_REMOTE
case ${WHC_PROFILE:-} in
    home) export WHC_HOME=true ;;
    work) export WHC_WORK=true ;;
    remote) export WHC_REMOTE=true ;;
esac

if [[ -n "$SSH_CONNECTION" ]]; then
    # Connection context is independent from the machine profile.
    export WHC_REMOTE=true
else
    export WHC_LOCAL=true
fi

export WHC_PROJECTS_DIR="$HOME/projects"

export VISUAL=nvim
export EDITOR="$VISUAL"

export ZSH_THEME="powerlevel10k/powerlevel10k"

export ANTIDOTE_DIR=${ZDOTDIR:-~}/.antidote
