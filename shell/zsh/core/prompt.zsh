# Dracula Powerlevel10k theme with explicit RGB colours. Load before Antidote.
source "${${(%):-%x}:A:h:h:h}/themes/dracula-powerlevel10k/p10k.zsh"

# Local integration settings; keep integration separate from theme colours.
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(whc_remote "${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[@]}")
# Keep hex lowercase: ZLE normalizes region_highlight, and autosuggestions
# must match that exact value to remove the hint colour after accepting/history.
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6272a4'

prompt_whc_remote() {
    [[ ${WHC_PROFILE:-} == remote || -n ${SSH_CONNECTION:-} || -n ${SSH_TTY:-} ]] || return 0
    local device=${WHC_DEVICE:-${HOST%%.*}}
    device=${device//[[:cntrl:]]/}
    # Device names are literal text, including any prompt escape characters.
    p10k segment -b '#FF5555' -f '#282A36' -t "%B${device//\%/%%}%b"
}

# Apply local settings when reloading an existing Powerlevel10k shell.
(( ! $+functions[p10k] )) || p10k reload
