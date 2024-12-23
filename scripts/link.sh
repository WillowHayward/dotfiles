#!/bin/bash
# Create symlinks between configurations in this repo and their destinations
declare -A links #links[TARGET]="DESTINATION" (DESTINATION will be prefixed with $HOME/)
links[.zshrc]=".zshrc"
links[.zsh_plugins.txt]=".zsh_plugins.txt"
links[.gitconfig]=".gitconfig"
links[.tmux.conf]=".tmux.conf"
links[nvim]=".config/nvim"
links[.npmrc]=".npmrc"
links[.vimrc]=".vimrc"
links[.yarnrc.yml]=".yarnrc.yml"

links[.taskrc]=".taskrc"

for link in "${!links[@]}"; do
    TARGET=$PWD/$link 
    DESTINATION=$HOME/${links[$link]} 
    if [[ -f "$DESTINATION" || -d "$DESTINATION" ]]; then
        echo $DESTINATION already exists, skipping
    else
        echo Linking $TARGET to $DESTINATION 
        ln -s $TARGET $DESTINATION
    fi
done
