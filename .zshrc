# Entry point for my zsh configuration - this bootstraps everything in $HOME/dotfiles/zsh
# NOTE: This file assumes that the dotfiles repository is located in $HOME/dotfiles

source_files() {
    local files=("$@")
    for file in $files; do
        source $zsh_root/$file
    done
}

autoload -U add-zsh-hook

zsh_root="$HOME/dotfiles/zsh"
load_first=(env.zsh)
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

[ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
