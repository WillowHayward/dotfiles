# Loader only: the configuration lives in zsh/ and is layered by profile.
#
#   core/     every profile (including remote): prompt, plugins, history, aliases
#   dev/      home and work: language toolchains and developer tooling
#   profile/  one file per WHC_PROFILE (home, work, remote)
#   context/  how the shell was reached (local terminal vs. SSH)
#
# WHC_PROFILE comes from /etc/environment (see `just setup init-system`).

zsh_root=${${(%):-%x}:A:h}/zsh # Resolve the .zshrc symlink so the repo can live anywhere.

whc_source() {
    [[ -r $zsh_root/$1 ]] && source "$zsh_root/$1"
}

# env.zsh derives WHC_PROFILE; everything below branches on it. The prompt is
# configured before plugins load, and compinit runs first because Oh My Zsh
# plugins call compdef while loading.
whc_source core/env.zsh
whc_source core/path.zsh
whc_source core/prompt.zsh
autoload -Uz compinit && compinit
whc_source core/plugins.zsh
whc_source core/functions.zsh
whc_source core/keys.zsh
whc_source core/aliases.zsh

if [[ -v WHC_DEV ]]; then
    whc_source dev/fnm.zsh
    whc_source dev/aliases.zsh
    for file in "$zsh_root"/dev/functions/*.zsh(N); do
        source "$file"
    done
    whc_source dev/completions.zsh
fi

whc_source core/history.zsh # Last, so nothing above overrides the history settings.

# Profile and connection context. Profile (home/work/remote) is exclusive;
# context (local/SSH) is independent of it. context/local.zsh may exec tmux,
# so it must stay last.
whc_source profile/${WHC_PROFILE:-remote}.zsh
[[ -v WHC_LOCAL ]] && whc_source context/local.zsh

unset file
