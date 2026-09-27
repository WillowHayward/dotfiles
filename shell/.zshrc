
source_files() {
    local files=("$@")
    for file in $files; do
        source $zsh_root/$file
    done
}

autoload -U add-zsh-hook
autoload -U +X compinit && compinit

zsh_root="$HOME/dotfiles/shell/zsh"
load_first=(env.zsh functions.zsh prompt.zsh) # Configure the prompt before plugins.
load_last=(history.zsh)
skip=(home.zsh work.zsh remote.zsh local.zsh)

# Source the first files
source_files $load_first

# Get all zsh files and source them, excluding the first and last files
all_files=($(ls $zsh_root))
for file in $all_files; do
    if (( ${load_first[(Ie)$file]} == 0 && ${load_last[(Ie)$file]} == 0 && ${skip[(Ie)$file]} == 0 )); then
        source $zsh_root/$file
    fi
done

# Source the last files
source_files $load_last


# Load environment-specific files
# Note - home/work are exclusive, and local/remote are exclusive, but those pairs can (and usually will be) mixed and matches
declare -A envs # A map of env vars to test and the files in ./zsh/ to source. envs[ENV_VAR]="file.zsh"
envs[WHC_HOME]="home.zsh"
envs[WHC_WORK]="work.zsh"
envs[WHC_LOCAL]="local.zsh"
envs[WHC_REMOTE]="remote.zsh"

for var in "${(@k)envs}"; do
    if [[ -v ${var} ]]; then
        source $zsh_root/${envs[$var]}
    fi
done

# Load Angular CLI autocompletion when installed for this Node version.
if (( $+commands[ng] )); then
    source <(ng completion script)
fi
