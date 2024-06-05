# This file contains utility functions and commands I want to exist
# /loads them from the functions subdirectory

local functions_root="$WHC_DOTFILES_DIR/zsh/functions"
all_files=($(ls $functions_root))
for file in $all_files; do
    source "$functions_root/$file"
done
