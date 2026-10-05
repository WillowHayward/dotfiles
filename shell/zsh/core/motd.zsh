# A small, extensible login banner. `whc_motd` runs every shell/motd.d/NN-name.zsh in
# order; a segment just prints what it wants (helpers below). Drop a new file in
# motd.d to add one, and name it with a lower number to move it up.
#
# It only runs where it helps (see profile/remote.zsh): an interactive SSH login on a
# remote machine, outside tmux, once per login. WHC_MOTD=0 silences it entirely.

# Helpers for segments.
motd_heading() { print -P "%F{#BD93F9}%B$1%b%f"; }
motd_row() { print -P "  %F{#6272A4}${(r:10:)1}%f ${2//\%/%%}"; }
motd_rule() { local width=${COLUMNS:-60}; print -P "%F{#44475A}${(l:$width::─:)}%f"; }

whc_motd() {
    [[ ${WHC_MOTD:-1} == 0 || -n ${WHC_MOTD_SHOWN:-} || -n ${TMUX:-} ]] && return 0
    [[ -o interactive && -n ${SSH_CONNECTION:-} ]] || return 0
    export WHC_MOTD_SHOWN=1
    local segment
    for segment in "${WHC_DOTFILES_DIR:-$HOME/dotfiles}"/shell/motd.d/*.zsh(N); do
        source "$segment"
    done
}
