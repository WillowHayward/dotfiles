# Function: tms
# Description: Start a new session in a given directory, with a given name
# Args:
#   $1 - Session directory (optional)
#       If not provided, defaults to $HOME
#   $2 - Session name (optional)
#       If not provided, defaults to basename of $1 or 'general'

# Default default directory
function tms() {
    local DIRECTORY=${1:-"$HOME"} SESSION_NAME i
    if [[ $# == 0 ]]; then
        if [[ -n "$TMUX" ]]; then
            tmux has-session -t '=general' 2>/dev/null || tmux new-session -d -s general -c "$HOME"
            tmux switch-client -t '=general'
        else
            tmux new-session -A -s general -c "$HOME"
        fi
        return
    fi

    # If the directory does not start with ~ or /, treat it as relative to the current directory
    [[ "$DIRECTORY" != /* && "$DIRECTORY" != ~* ]] && DIRECTORY="$(pwd)/$DIRECTORY"

    # Default session name directory
    if [ -z "$1" ]; then
        SESSION_NAME=${2:-"general"}
    else
        SESSION_NAME=${2:-$(basename "$DIRECTORY")}
    fi

    # Check if a session with the same name already exists
    if tmux has-session -t "=$SESSION_NAME" 2>/dev/null; then
        # If a session with the same name exists, append a number to make it unique
        i=1
        while tmux has-session -t "=${SESSION_NAME}_$i" 2>/dev/null; do
            i=$((i+1))
        done
        SESSION_NAME="${SESSION_NAME}_$i"
    fi

    # Start a new tmux session with the provided name and directory
    tmux new-session -d -s "$SESSION_NAME" -c "$DIRECTORY"

    # Switch to the new session
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "=$SESSION_NAME"
    else
        tmux attach-session -t "=$SESSION_NAME"
    fi
}
