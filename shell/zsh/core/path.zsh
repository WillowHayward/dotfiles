# Keep PATH unique; zsh ties the `path` array to $PATH.
typeset -gU path
path=("$HOME/.local/bin" $path)

# Optional toolchains: only add what exists on this machine.
for dir in "$HOME/.cargo/bin" "$HOME/android-studio/bin" /opt/nvim-linux64/bin; do
    [[ -d $dir ]] && path+=("$dir")
done
unset dir
