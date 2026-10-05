# Configuration particular to remote servers (lightweight, Debian family).
# Sourced last, only when WHC_PROFILE=remote. The remote-device prompt segment
# is managed by core/prompt.zsh. Keep anything private in
# profile/remote.local.zsh, which is not tracked.

[[ -r ${${(%):-%x}:A:h}/remote.local.zsh ]] && source "${${(%):-%x}:A:h}/remote.local.zsh"
