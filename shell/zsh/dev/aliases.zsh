# Developer tooling aliases (home and work).
alias lg='lazygit'

# Taskwarrior. ~/.taskrc includes ~/.taskrc.local (sync settings), which must exist.
(( $+commands[task] )) && [[ ! -e ~/.taskrc.local ]] && : >> ~/.taskrc.local
alias ta='task add'
alias te='task edit'
alias td='task done'
alias tc='task context'
alias tl='task list'
alias ti='task info'
alias tcn='task context none'
# tap defined as function - adds task to project
