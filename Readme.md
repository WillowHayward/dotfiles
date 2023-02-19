These are the dotfiles I use to make my dev experience more universal across devices.

# Usage
This is primarily designed for use in a system like Ubuntu.

A lot of symlinks coming, so buckle up.

| dotfile           | System Location         | Description                                                                                                                                                                     |
|-------------------|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| .zshrc            | ~/.zshrc | zsh config - I used https://ohmyz.sh/ as well |
| .gitconfig        | ~/.gitconfig            | Global git settings - this includes my name personal information (name, email) as well as some quality of life settings.                                                        |
| .gitignore.global | ~/.gitignore            | Global git ignore - Set up in the .gitconfig.                                                                                                                                   |
| .tmux.conf        | ~/.tmux.conf            | Tmux settings - I use [Tmux Package Manager](https://github.com/tmux-plugins/tpm) so that has to be installed first.                                                            |
| .npmrc            | ~/.npmrc                | NPM settings - Mostly initial project setup things like my name and email, MIT license, version 0.0.1.                                                                          |
| .vimrc            | ~/.config/nvim/init.vim | My Neovim settings - some of it may be backwards compatible with vim, but some of it might not be. I use [vim-plug](https://github.com/junegunn/vim-plug) as my plugin manager. |

To automate the setup of the file locations, run `./setup.sh`. Some require further setup.

