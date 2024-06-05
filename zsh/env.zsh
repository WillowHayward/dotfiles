# Environment variables - To be run at the start of zsh launch
# WHC_ prefix for Willow Hayward Code stuff
export ZSH="$HOME/.oh-my-zsh"
export WHC_DOTFILES_DIR="$HOME/dotfiles"
if [[ -f "$WHC_DOTFILES_DIR/.env" ]]; then # Global environment variables not for committing
    set -o allexport
    source "$WHC_DOTFILES_DIR/.env"
    set +o allexport
fi

if [[ -n "$WSLENV" ]]; then
    # If WSLENV is set, this is probably my work setup
    export WHC_WORK=true
else
    export WHC_HOME=true
fi

if [[ -n "$SSH_CONNECTION" ]]; then
    # If SSH_CONNECTION is set, this is probably a remote session
    export WHC_REMOTE=true
else
    export WHC_LOCAL=true
fi

export WHC_PROJECTS_DIR="$HOME/projects"

export VISUAL=nvim
export EDITOR="$VISUAL"

export ZSH_THEME="robbyrussell"

export ANTIDOTE_DIR=${ZDOTDIR:-~}/.antidote
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
