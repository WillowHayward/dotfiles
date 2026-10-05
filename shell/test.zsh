#!/usr/bin/env zsh
# Checks the zsh loader's scoping rules. Run with `zsh shell/test.zsh` (part of `just test`).
# .zshrc sources the layers from inside a function, where a plain `typeset` is local
# and would silently discard PATH changes once the function returns.
setopt err_exit no_unset
root=${${(%):-%x}:A:h}
home=$(mktemp -d)
trap 'rm -rf -- "$home"' EXIT
mkdir -p "$home/.local/bin" "$home/.local/share/fnm" "$home/.cargo/bin"
printf '#!/bin/sh\n' > "$home/.local/share/fnm/fnm" # `fnm env` prints nothing
chmod +x "$home/.local/share/fnm/fnm"

HOME=$home
unset FNM_DIR FNM_MULTISHELL_PATH
path=(/usr/bin /bin)
whc_source() { source "$root/zsh/$1" }

whc_source core/path.zsh
[[ ${path[1]} == "$home/.local/bin" ]] || { print -u2 "path.zsh did not put ~/.local/bin first: $path"; exit 1 }
[[ ${path[(Ie)$home/.cargo/bin]} != 0 ]] || { print -u2 "path.zsh dropped ~/.cargo/bin: $path"; exit 1 }

whc_source dev/fnm.zsh
[[ ${path[1]} == "$home/.local/share/fnm" ]] || { print -u2 "fnm.zsh did not put the fnm directory first: $path"; exit 1 }
(( $+commands[fnm] )) || { print -u2 "fnm is not resolvable after fnm.zsh: $path"; exit 1 }
[[ ${#path} == ${#${(u)path}} ]] || { print -u2 "path has duplicates: $path"; exit 1 }
print "zsh loader tests passed."
