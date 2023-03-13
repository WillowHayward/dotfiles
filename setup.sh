#!/bin/bash

# Assume $HOME/ as base for destinations
declare -A links
links[.zshrc]=".zshrc"
links[.gitconfig]=".gitconfig"
links[.tmux.conf]=".tmux.conf"
links[nvim]=".config/nvim"
links[.npmrc]=".npmrc"
links[.vimrc]=".vimrc"

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
