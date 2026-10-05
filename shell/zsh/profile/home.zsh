# Configuration particular to my home (Arch) machines.
# Sourced last, only when WHC_PROFILE=home. Keep anything private in
# profile/home.local.zsh, which is not tracked.

alias cdm='cd $HOME/monoverse/'

# Horace
alias log="cargo run -p lifesuite-journal-cli"
export HORACE_ROOT=$HOME/.horace

alias rot="task add project:stop-the-rot"

alias sshw="ssh whc.fyi"
alias sshb="ssh whc.boats"
alias sshr="ssh raspberrypi"

function hello() {
  echo "Hello, fucksticks!"
}

[[ -r ${${(%):-%x}:A:h}/home.local.zsh ]] && source "${${(%):-%x}:A:h}/home.local.zsh"
