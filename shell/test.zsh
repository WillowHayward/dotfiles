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

# cdd/cdp/cdi: root, immediate subdirectory, and rejections.
export WHC_DOTFILES_DIR=$home/dot WHC_PROJECTS_DIR=$home/proj WHC_INFRA_DIR=$home/infra
mkdir -p "$WHC_DOTFILES_DIR/shell" "$WHC_PROJECTS_DIR/app/src" "$WHC_INFRA_DIR/web"
compdef() { :; } # completion is not initialised in this test
source "$root/zsh/core/functions/cd-dirs.zsh"
cdp; [[ $PWD == $WHC_PROJECTS_DIR ]] || { print -u2 "cdp did not go to the projects root"; exit 1 }
cdp app/; [[ $PWD == $WHC_PROJECTS_DIR/app ]] || { print -u2 "cdp app failed"; exit 1 }
cdi web; [[ $PWD == $WHC_INFRA_DIR/web ]] || { print -u2 "cdi web failed"; exit 1 }
cdd; [[ $PWD == $WHC_DOTFILES_DIR ]] || { print -u2 "cdd did not go to the dotfiles root"; exit 1 }
cdd shell; [[ $PWD == $WHC_DOTFILES_DIR/shell ]] || { print -u2 "cdd shell failed"; exit 1 }
cd "$home"
for bad in app/src .. . missing; do
    if cdp $bad 2>/dev/null; then print -u2 "cdp accepted '$bad'"; exit 1; fi
    [[ $PWD == $home ]] || { print -u2 "cdp moved on rejected '$bad'"; exit 1 }
done
if cdp a b 2>/dev/null; then print -u2 "cdp accepted two arguments"; exit 1; fi

# pp dispatch: terminal picker, direct open, and refresh without an empty argument.
source "$root/zsh/dev/functions/pp.zsh"
python3() { pp_args=("$@"); }
typeset -a pp_args
pp
[[ ${pp_args[-1]} == terminal-pick ]] || { print -u2 "pp did not open the terminal picker"; exit 1; }
pp app
[[ ${pp_args[-2,-1]} == (terminal-open app) ]] || { print -u2 "pp did not open app"; exit 1; }
pp --refresh
[[ ${#pp_args} == 2 && ${pp_args[-1]} == refresh ]] \
    || { print -u2 "pp --refresh passed an unexpected target"; exit 1; }
pp --refresh app
[[ ${pp_args[-2,-1]} == (refresh app) ]] || { print -u2 "pp did not refresh app"; exit 1; }
if pp one two 2>/dev/null; then print -u2 "pp accepted too many arguments"; exit 1; fi
print "zsh loader tests passed."
