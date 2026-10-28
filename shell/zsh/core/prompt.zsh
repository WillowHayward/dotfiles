# Dracula Powerlevel10k theme with explicit RGB colours. Load before Antidote. whc-theme's
# generated file (`just theme apply <theme>`) then re-colours it for the current theme and machine,
# and sets the fzf, autosuggestion and lazygit colours.
source "${${(%):-%x}:A:h:h:h}/themes/dracula-powerlevel10k/p10k.zsh"
[[ -r ${${(%):-%x}:A:h:h:h}/themes/whc-theme.zsh ]] && source "${${(%):-%x}:A:h:h:h}/themes/whc-theme.zsh"

# Local integration settings; keep integration separate from theme colours.
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
# The first segment names the machine: OS logo and device name (just the logo locally on
# home), in the machine's brand colour from whc-theme, except on remote machines and SSH sessions,
# which are vibrant red and also carry the user (user@device), so the right-hand context segment
# is hidden over SSH.
typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(whc_host "${(@)POWERLEVEL9K_LEFT_PROMPT_ELEMENTS:#os_icon}")
# Keep hex lowercase: ZLE normalizes region_highlight, and autosuggestions
# must match that exact value to remove the hint colour after accepting/history.
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${(L)whc_theme[bright_black]:-#6272a4}"

typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=

# Nerd Font glyphs by os-release ID; unknown systems get the generic Linux logo.
typeset -gA _whc_os_icons=(arch $'\uf303' debian $'\uf306' ubuntu $'\uf31b' fedora $'\uf30a' alpine $'\uf300')
_whc_os_icon=$'\uf17c'
if [[ -v WHC_TERMUX ]]; then
    _whc_os_icon=$'\ue70e' # Android
elif [[ -r /etc/os-release ]]; then
    _whc_os_id=$(sed -n 's/^ID="\{0,1\}\([a-z0-9._-]*\)"\{0,1\}$/\1/p' /etc/os-release | head -n1)
    _whc_os_icon=${_whc_os_icons[$_whc_os_id]:-$_whc_os_icon}
    unset _whc_os_id
fi

prompt_whc_host() {
    local device=${WHC_DEVICE:-${HOST%%.*}}
    local background=${whc_theme[status_bg]:-#6272A4} foreground=${whc_theme[status_fg]:-#F8F8F2}
    device=${device//[[:cntrl:]]/}
    if [[ ${WHC_PROFILE:-} == remote || -n ${SSH_CONNECTION:-} || -n ${SSH_TTY:-} ]]; then
        background=#FF1F1F foreground=#FFFFFF
        device="${USER//[[:cntrl:]]/}@$device"
    elif [[ ${WHC_PROFILE:-} == home ]]; then
        p10k segment -b $background -f $foreground -t "$_whc_os_icon"
        return
    fi
    # Device names are literal text, including any prompt escape characters.
    p10k segment -b $background -f $foreground -t "$_whc_os_icon %B${device//\%/%%}%b"
}

# Apply local settings when reloading an existing Powerlevel10k shell.
(( ! $+functions[p10k] )) || p10k reload
