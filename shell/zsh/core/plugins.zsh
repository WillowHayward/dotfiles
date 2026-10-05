# Plugin lists live in shell/plugins/: core.txt for every profile, dev.txt on
# top of it for home and work. Antidote only reads one bundle file, so the
# combined list is generated into the cache and rebuilt when a source changes.
# Cloning must ignore ~/.gitconfig: the profile configs rewrite github.com URLs
# to SSH, and a new machine has no GitHub key yet.
if [[ ! -d ${ANTIDOTE_DIR} ]]; then
    GIT_CONFIG_GLOBAL=/dev/null git clone --depth=1 https://github.com/mattmc3/antidote.git "${ANTIDOTE_DIR}"
fi

whc_plugin_sources=("$WHC_DOTFILES_DIR/shell/plugins/core.txt")
[[ -v WHC_DEV ]] && whc_plugin_sources+=("$WHC_DOTFILES_DIR/shell/plugins/dev.txt")
whc_plugin_bundle="${XDG_CACHE_HOME:-$HOME/.cache}/whc/zsh_plugins.${WHC_PROFILE}.txt"
whc_plugin_static="${whc_plugin_bundle:r}.zsh"

for whc_plugin_source in $whc_plugin_sources; do
    if [[ ! -s $whc_plugin_bundle || $whc_plugin_source -nt $whc_plugin_bundle ]]; then
        mkdir -p "${whc_plugin_bundle:h}"
        cat $whc_plugin_sources >| "$whc_plugin_bundle"
        break
    fi
done

source ${ANTIDOTE_DIR}/antidote.zsh
# Same as `antidote load`: regenerate the static file when the bundle changes.
if [[ ! -s $whc_plugin_static || $whc_plugin_bundle -nt $whc_plugin_static ]]; then
    (GIT_CONFIG_GLOBAL=/dev/null antidote bundle < "$whc_plugin_bundle" >| "$whc_plugin_static")
fi
source "$whc_plugin_static"
unset whc_plugin_sources whc_plugin_bundle whc_plugin_static whc_plugin_source
