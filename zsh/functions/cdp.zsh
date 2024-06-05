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

# Autocomplete for `cdp`
_cdp_dirs() {
  local -a dirs
  dirs=($(ls -d "$WHC_PROJECTS_DIR"/*/))
  _describe 'directory' dirs
}

compctl -K _cdp_dirs cdp
