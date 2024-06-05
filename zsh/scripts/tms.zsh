# Utility script for the `tms` command to start a new session
# Args:
#   $1 - Session directory (optional)
#   $2 - Session name (optional)

# Default session name
SESSION_NAME="default_session"

# Default directory
DIRECTORY="$HOME"

# Check if a directory was provided
if [ ! -z "$1" ]
then
  DIRECTORY="$1"
fi

# Check if a session name was provided
if [ ! -z "$2" ]
then
  SESSION_NAME="$2"
else
  SESSION_NAME=$(basename "$DIRECTORY")
fi

# Check if a session with the same name already exists
SESSION_EXISTS=$(tmux list-sessions | awk -F: '{print $1}' | grep "^$SESSION_NAME$")

# If a session with the same name exists, append a number to make it unique
if [ ! -z "$SESSION_EXISTS" ]
then
  i=1
  while true; do
    NEW_SESSION_NAME="${SESSION_NAME}_$i"
    SESSION_EXISTS=$(tmux list-sessions | awk -F: '{print $1}' | grep "^$NEW_SESSION_NAME$")
    if [ -z "$SESSION_EXISTS" ]; then
      SESSION_NAME=$NEW_SESSION_NAME
      break
    fi
    i=$((i+1))
  done
fi

# Start a new tmux session with the provided name and directory
tmux new-session -d -s $SESSION_NAME -c $DIRECTORY

# Switch to the new session
tmux switch-client -t $SESSION_NAME
