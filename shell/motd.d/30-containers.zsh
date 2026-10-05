# Running containers, when docker is installed and reachable by this user.
if (( $+commands[docker] )); then
    local containers
    containers=$(docker ps --format '{{.Names}}' 2>/dev/null) && \
        motd_row containers "$(print -r -- $containers | wc -l) running"
fi
