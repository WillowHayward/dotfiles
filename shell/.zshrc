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
# configured before plugins load; core/plugins.zsh runs compinit between its stages.
whc_source core/env.zsh
whc_source core/path.zsh
# Local terminals hand over to tmux now, before the slow parts load, so the full init runs
# once (inside tmux) instead of twice. Each pane runs this file itself, so it still gets
# fnm, plugins and the prompt; the tmux server only inherits the environment set above.
[[ -v WHC_LOCAL ]] && whc_source context/local.zsh
whc_source core/prompt.zsh
whc_source core/plugins.zsh
whc_source core/functions.zsh
whc_source core/keys.zsh
whc_source core/aliases.zsh

if [[ -v WHC_DEV ]]; then
    whc_source dev/fnm.zsh
    whc_source dev/aliases.zsh
    whc_source dev/direnv.zsh
    for file in "$zsh_root"/dev/functions/*.zsh(N); do
        source "$file"
    done
    whc_source dev/completions.zsh
fi

whc_source core/history.zsh # Last, so nothing above overrides the history settings.

# Profile (home/work/remote) is exclusive; connection context (local/SSH) is independent
# of it and handled above (context/local.zsh).
whc_source profile/${WHC_PROFILE:-remote}.zsh

unset file
