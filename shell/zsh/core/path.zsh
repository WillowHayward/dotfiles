# Keep PATH unique; zsh ties the `path` array to $PATH.
typeset -gU path
path=("$HOME/.local/bin" $path)

# Optional toolchains: only add what exists on this machine.
for dir in "$HOME/.cargo/bin" "$HOME/android-studio/bin" /opt/nvim-linux64/bin; do
    [[ -d $dir ]] && path+=("$dir")
done
unset dir

# pnpm's managed installation and global executables.
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
# An if, not &&: a false test as the last command would make sourcing this file fail.
if [[ -d "$PNPM_HOME/bin" ]]; then
    path=("$PNPM_HOME/bin" $path)
fi
