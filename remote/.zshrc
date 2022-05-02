export ZSH="/home/willhay/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git laravel vi-mode zsh-autosuggestions nx-completion)
source $ZSH/oh-my-zsh.sh

bindkey -v

export VISUAL=nvim
export EDITOR="$VISUAL"

# Load NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
