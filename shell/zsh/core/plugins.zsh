# Plugin lists live in shell/plugins/ and are pinned to commits:
setopt local_options extended_glob # for the (#q...) glob qualifier below
#   early.txt  fpath-only plugins, loaded before compinit
#   core.txt   every profile        dev.txt  added for home and work
#   last.txt   must load last (syntax highlighting)
# Antidote reads one bundle file, so each stage is generated into the cache and rebuilt
# when a source changes. Cloning ignores ~/.gitconfig: the profile configs rewrite
# github.com URLs, and a new machine has no GitHub key yet.
whc_pins=$WHC_DOTFILES_DIR/setup/pins.env
[[ -r $whc_pins ]] && source "$whc_pins"
if [[ ! -d ${ANTIDOTE_DIR} ]]; then
    GIT_CONFIG_GLOBAL=/dev/null git clone --quiet https://github.com/mattmc3/antidote.git "${ANTIDOTE_DIR}"
    [[ -n ${ANTIDOTE_REF:-} ]] && git -C "${ANTIDOTE_DIR}" -c advice.detachedHead=false checkout --quiet "$ANTIDOTE_REF"
fi
unset whc_pins

source ${ANTIDOTE_DIR}/antidote.zsh

# Bundle the given plugin lists into the cache under <name> and source the result.
whc_antidote_load() {
    local name=$1; shift
    local bundle="${XDG_CACHE_HOME:-$HOME/.cache}/whc/zsh_plugins.${WHC_PROFILE}.${name}.txt"
    local static="${bundle:r}.zsh" file stale=
    local -a sources=("$@")
    for file in $sources; do
        [[ ! -s $bundle || $file -nt $bundle ]] && stale=1
    done
    if [[ -n $stale ]]; then
        mkdir -p "${bundle:h}"
        cat $sources >| "$bundle"
    fi
    # Same as `antidote load`: regenerate the static file when the bundle changes.
    if [[ ! -s $static || $bundle -nt $static ]]; then
        (GIT_CONFIG_GLOBAL=/dev/null antidote bundle < "$bundle" >| "$static")
    fi
    source "$static"
}

local plugins=$WHC_DOTFILES_DIR/shell/plugins
whc_antidote_load early $plugins/early.txt

# Oh My Zsh plugins call compdef while loading, so compinit runs between the stages.
# The dump is rebuilt when it is a day old; otherwise -C skips the audit and the rescan.
autoload -Uz compinit
local zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/whc/zcompdump"
mkdir -p "${zcompdump:h}"
if [[ -n $zcompdump(#qN.mh+24) || ! -s $zcompdump ]]; then
    compinit -d "$zcompdump"
else
    compinit -C -d "$zcompdump"
fi

local -a stages=($plugins/core.txt)
[[ -v WHC_DEV ]] && stages+=($plugins/dev.txt)
whc_antidote_load main $stages
whc_antidote_load last $plugins/last.txt
unfunction whc_antidote_load
