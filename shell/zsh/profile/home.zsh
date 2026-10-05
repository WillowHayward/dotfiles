# Configuration particular to my home (Arch) machines.
# Sourced last, only when WHC_PROFILE=home. Personal aliases, project shortcuts and
# host names live in profile/home.local.zsh, which is not tracked.

[[ -r ${${(%):-%x}:A:h}/home.local.zsh ]] && source "${${(%):-%x}:A:h}/home.local.zsh"
