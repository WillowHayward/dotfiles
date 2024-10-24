#!/bin/bash
# Install all the core linux stuff

# Install important applications
dev = build-essential git lazygit
apps = zsh

apt-get update
apt-get install $dev -y
apt-get install $apps -y

# Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# Ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
# TODO move to tmp and change to apt install
# TODO Maybe even just move to apt-get install ripgrep
dpkg -i ripgrep_13.0.0_amd64.deb

# NeoVim
nvim_stable="https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb"
wget -P /tmp 
apt install /tmp/nvim-linux64.deb

# Tmux
# https://github.com/tmux/tmux/releases/tag/3.3
# Set up tpm (if not set up)
# TODO Does this need to be conditional?
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

