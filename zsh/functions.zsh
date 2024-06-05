# This file contains utility functions and commands I want to exists

# Function: cdp
# Description: Changes the current directory to WHC_PROJECTS_DIR or a subdirectory of WHC_PROJECTS_DIR.
# Args:
#   $1 - The name of a subdirectory in WHC_PROJECTS_DIR (optional).
#       If provided, the function will change the current directory to WHC_PROJECTS_DIR/$1.
#       If not provided, the function will change the current directory to WHC_PROJECTS_DIR.
function cdp() {
    # Check if an argument was provided
    if [ $# -eq 0 ]
    then
        # No arguments, cd to WHC_PROJECTS_DIR
        cd "$WHC_PROJECTS_DIR"
    else
        # Argument provided, cd to WHC_PROJECTS_DIR/<arg>
        cd "$WHC_PROJECTS_DIR/$1"
    fi
}

# Function: tms
# Description: Start a new session in a given directory, with a given name
# Args:
#   $1 - Session directory (optional)
#       If not provided, defaults to $HOME
#   $2 - Session name (optional)
#       If not provided, defaults to basename of $1 or 'default_session'

# Default default directory
function tms() {
    DIRECTORY=${1:-"$HOME"}

    # If the directory does not start with ~ or /, treat it as relative to the current directory
    [[ "$DIRECTORY" != /* && "$DIRECTORY" != ~* ]] && DIRECTORY="$(pwd)/$DIRECTORY"

    # Default session name directory
    if [ -z "$1" ]; then
        # If no directory is provided, SESSION_NAME should default to 'default_session'
        SESSION_NAME=${2:-"default_session"}
    else
        SESSION_NAME=${2:-$(basename "$DIRECTORY")}
    fi

    # Check if a session with the same name already exists
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # If a session with the same name exists, append a number to make it unique
        i=1
        while tmux has-session -t "${SESSION_NAME}_$i" 2>/dev/null; do
            i=$((i+1))
        done
        SESSION_NAME="${SESSION_NAME}_$i"
    fi

    # Start a new tmux session with the provided name and directory
    tmux new-session -d -s $SESSION_NAME -c $DIRECTORY

    # Switch to the new session
    tmux switch-client -t $SESSION_NAME
}

# Function: tap
# Description: Add a task to TaskWarrior with the project tag
# Args:
#  $1 - Project name
# The remainder of args will be taken as the task description
function tap() {
    if [ $# -eq 0 ]; then
        echo "Must provide a project. And a description, actually. Whaddaya doing, pal"
    fi

    task add project:$@
}

# Autocomplete for `tap`
_tap_autocomplete() {
    local -a project_names
    project_names=("${(@f)$(task _projects)}")
    _describe 'values' project_names
}

_tap() {
    if (( CURRENT == 2 )); then
        _tap_autocomplete
    else
        _default
    fi
}

compdef _tap tap
