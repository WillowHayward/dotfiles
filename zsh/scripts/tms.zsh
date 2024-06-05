# Utility script for the `tms` command to start a new session
# Args:
#   $1 - Session directory (optional)
#   $2 - Session name (optional)

# Default default directory
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
