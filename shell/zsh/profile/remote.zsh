# Configuration particular to remote servers (lightweight, Debian family).
# Sourced last, only when WHC_PROFILE=remote. The prompt prefix is managed by core/prompt.zsh.
# Keep anything private in profile/remote.local.zsh, which is not tracked.

# Login banner: shell/motd.d/*.zsh, shown on interactive SSH logins only.
source "${${(%):-%x}:A:h:h}/core/motd.zsh"
whc_motd

[[ -r ${${(%):-%x}:A:h}/remote.local.zsh ]] && source "${${(%):-%x}:A:h}/remote.local.zsh"
