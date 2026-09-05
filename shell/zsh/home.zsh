# This file is for configuration particular to my home computer, and will not always be committed
# It will be loaded nearly last, and only if WHC_HOME is set
# Horace
alias log="cargo run -p lifesuite-journal-cli"
export HORACE_ROOT=$WHC_HOME/.horace

alias rot="task add project:stop-the-rot"

alias sshw="ssh whc.fyi"
alias sshb="ssh whc.boats"
alias sshr="ssh raspberrypi"

function hello() {
  echo "Hello, fucksticks!"
}
