
bindkey -v # Turn on vim mappings
if [[ -v WHC_HOME && -v WHC_LOCAL ]]; then
    setxkbmap -option caps:swapescape # Swap caps and escape, but only for local home connections
fi

# Keymaps
alias n='nvim'

# Location shortcuts
if [[ -v WHC_HOME ]]; then
    alias cdm='cd $HOME/monoverse/'
fi
alias cdp='cd $HOME/projects/'
alias cdd='cd $HOME/dotfiles/'
alias cdD='cd $HOME/docker/' # TODO: Consider "containers"?

# Taskwarrior
alias ta='task add'
alias te='task edit'
alias td='task done'
alias tc='task context'
alias tl='task list'
alias ti='task info'
alias tcn='task context none'

# Git # TODO: Check against https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L103
alias gs='git status'

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
