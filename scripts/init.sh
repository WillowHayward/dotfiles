#!/bin/bash
# Install all the core linux stuff

# Install important applications
apps = git zsh

apt-get update
apt-get install $apps -y

# NeoVim
nvim_stable="https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb"
wget -P /tmp 
apt install /tmp/nvim-linux64.deb

# Tmux
# https://github.com/tmux/tmux/releases/tag/3.3
# Set up tpm (if not set up)
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# zsh
# TODO: Getting zsh other than from apt would be pretty cool
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
rm $HOME/.zshrc # Remote default zshrc

# node
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
corepack enable

# Link config files
./link.sh

