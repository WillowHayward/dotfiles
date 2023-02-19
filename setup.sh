#!/bin/bash

declare -A links
links[.zshrc]="~/.zshrc"
links[.gitconfig]="~/.gitconfig"
links[.gitignore.global]="~/.gitignore"
links[.tmux.conf]="~/.tmux.conf"
links[.npmrc]="~/.npmrc"
links[.vimrc]="~/.config/nvim/init.vim"

for link in "${!links[@]}"; do
    echo Linking $link
    ln -s ${links[$link]} $link 
done
