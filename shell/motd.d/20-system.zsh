# Uptime, load, memory and root disk usage from /proc and df (no extra tools).
motd_rule
local uptime_seconds=${${(s: :)$(</proc/uptime)}[1]%.*}
motd_row uptime "$(( uptime_seconds / 86400 ))d $(( uptime_seconds % 86400 / 3600 ))h $(( uptime_seconds % 3600 / 60 ))m"
motd_row load "${(j: :)${(s: :)$(</proc/loadavg)}[1,3]}"
if [[ -r /proc/meminfo ]]; then
    local total=${${(M)${(f)"$(</proc/meminfo)"}:#MemTotal*}//[^0-9]/} available=${${(M)${(f)"$(</proc/meminfo)"}:#MemAvailable*}//[^0-9]/}
    motd_row memory "$(( (total - available) / 1024 )) / $(( total / 1024 )) MiB"
fi
motd_row disk "$(df -h / | awk 'NR==2 { print $3 " / " $2 " (" $5 ")" }')"
