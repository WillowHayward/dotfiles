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
[ ! -z "$WSLENV" && ! -z "$SSH_CONNECTION" ] && setxkbmap -option caps:swapescape # Swap caps and escape

# Load NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm


# Load nvmrc in directories with .nvmrc
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Launch tmux
[ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
cd $HOME

# added by pipx (https://github.com/pipxproject/pipx)
export PATH="/home/whayward/.local/bin:$PATH"

# added by pipx (https://github.com/pipxproject/pipx)
export PATH="/home/whayward/.local/bin:$PATH"

# For work
alias cdm="cd ~/monolith"

# Copilot suggestions
alias ll='ls -l'  # List directory contents in long format
alias la='ls -A'  # List all (including hidden) directory contents
alias l='ls -CF'  # List directory contents in column format
alias ..='cd ..'  # Go up one directory level
alias ...='cd ../..'  # Go up two directory levels
alias grep='grep --color=auto'  # Colorize output of grep
alias df='df -H'  # Display filesystem disk space usage in human-readable format
alias du='du -ch'  # Display directory space usage in human-readable format
alias mkdir='mkdir -pv'  # Make directories, including parent directories as needed, and print each directory name
alias hist='history | grep'  # Search command history
