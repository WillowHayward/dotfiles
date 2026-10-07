# Configuration particular to my phone (Termux on Android).
# Sourced last, only when WHC_PROFILE=mobile. Keep anything private in
# profile/mobile.local.zsh, which is not tracked.

# Hand URLs and files to Android (through the Termux:API app where needed).
if (( $+commands[termux-open-url] )); then
    export BROWSER=termux-open-url
    alias open='termux-open'
fi
# Share a file or stdin through Android's share sheet: `share notes.md`, `cmd | share`.
(( $+commands[termux-share] )) && alias share='termux-share -a send'

[[ -r ${${(%):-%x}:A:h}/mobile.local.zsh ]] && source "${${(%):-%x}:A:h}/mobile.local.zsh"
