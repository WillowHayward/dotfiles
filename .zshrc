# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Set up environment variables
DOTFILES="$HOME/dotfiles/.env"
if [[ -f "$DOTFILES" ]]; then 
    set -o allexport
    source $DOTFILES
    set +o allexport
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git laravel vi-mode zsh-autosuggestions nx-completion)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

bindkey -v

export VISUAL=nvim
export EDITOR="$VISUAL"
setxkbmap -option caps:swapescape # Swap caps and escape
# Load NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Launch tmux
[ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
