# Ensure that expected things are installed
#if [[ ! -d ${ZSH} ]]; then
    # Make sure that oh-my-zsh is installed
    #sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#fi

if [[ ! -d ${ANTIDOTE_DIR} ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
fi

#source $ZSH/oh-my-zsh.sh
