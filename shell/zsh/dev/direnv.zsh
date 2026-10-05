# direnv loads and unloads a project's .envrc as you enter and leave it
# (`direnv allow` approves one). `use_fnm` is defined in direnv/direnvrc.
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
