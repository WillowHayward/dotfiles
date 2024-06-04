# See .zsh_plugins.txt in the root for the list of plugins
if [[ ! -d ${ANTIDOTE_DIR} ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
fi

source ${ANTIDOTE_DIR}/antidote.zsh
antidote load
