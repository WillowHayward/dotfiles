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
