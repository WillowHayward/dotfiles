# Entry point for my zsh configuration - this bootstraps everything in $HOME/dotfiles/zsh
# NOTE: This file assumes that the dotfiles repository is located in $HOME/dotfiles
#
# install.zsh:12: parse error near `\n'
# nvm.zsh:22: command not found: add-zsh-hook


source_files() {
    local files=("$@")
    for file in $files; do
        source $zsh_root/$file
    done
}

zsh_root="$HOME/dotfiles/zsh"
#cd $zsh_root # tmux.zsh cds to $HOME
load_first=(env.zsh install.zsh autoload.zsh)
load_last=(work.zsh tmux.zsh)

# Source the first files
source_files $load_first

# Get all zsh files and source them, excluding the first and last files
all_files=($(ls $zsh_root))
for file in $all_files; do
    if (( ${load_first[(Ie)$file]} == 0 && ${load_last[(Ie)$file]} == 0 )); then
        source $zsh_root/$file
    fi
done

# Source the last files
source_files $load_last


# TODO: Find out why this is behaving strangely elsewhere
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
