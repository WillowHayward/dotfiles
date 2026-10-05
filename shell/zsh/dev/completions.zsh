# Load Angular CLI autocompletion when installed for this Node version.
if (( $+commands[ng] )); then
    source <(ng completion script)
fi
