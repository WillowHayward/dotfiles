#!/bin/bash
# Install all the core linux stuff

# Install important applications
apps = git zsh taskwarrior

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

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# node
bash "$(dirname -- "${BASH_SOURCE[0]}")/setup-node.sh"

# Link config files
./link.sh

# Rust 
# TODO: Make actually automated, and remove .zshrc (and related?) modification
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# ChatGPT
curl -L -o chatgpt https://github.com/kardolus/chatgpt-cli/releases/latest/download/chatgpt-linux-amd64 && chmod +x chatgpt && sudo mv chatgpt /usr/local/bin/
mkdir -p ~/.chatgpt-cli
