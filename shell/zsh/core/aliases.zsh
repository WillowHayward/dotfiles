# Aliases for every profile. Developer-only aliases live in dev/aliases.zsh and
# machine-specific ones in profile/.

# Location shortcuts
# cdd, cdp and cdi are functions (core/functions/cd-dirs.zsh): they cd to
# $WHC_DOTFILES_DIR, $WHC_PROJECTS_DIR and $WHC_INFRA_DIR, or to an immediate subdirectory.
alias cdc='cd $HOME/docker/' # TODO: Consider "containers"?
alias cdh='cd $HOME/'

# Editor (nvim where it is installed, vim on servers)
alias n='$EDITOR'

# Zsh
alias zshr='source ~/.zshrc'

# Tmux
alias tm='tmux'
# tms defined as function - creates new session
alias tmsd='tms "$WHC_DOTFILES_DIR"'

# Git # TODO: Check against https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L103
alias gs='git status'

# Docker
# NOTE: d and dc are already taken by other things
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs'
alias dl='docker logs'
alias dr='docker restart'
alias de='docker exec -it'
alias dcp='docker cp'

# Convenience defaults
alias ll='ls -lh'  # List directory contents in long format
alias la='ls -A'  # List all (including hidden) directory contents
alias l='ls -CF'  # List directory contents in column format
alias ..='cd ..'  # Go up one directory level
alias ...='cd ../..'  # Go up two directory levels
alias hist='history | grep'  # Search command history
