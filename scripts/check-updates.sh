#!/usr/bin/env bash
# Report newer upstream versions for everything pinned in setup/pins.env and shell/plugins/*.txt.
# Usage: scripts/check-updates.sh [--fail]   (--fail exits 1 when anything is behind)
# Pinned downloads need a checksum bump too: edit setup/pins.env, then run `just test-container`.
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../setup/pins.env
source "$root/setup/pins.env"
behind=0

report() { # name pinned latest
    local status=current
    if [[ -z $3 ]]; then
        status='unknown (lookup failed)'
    elif [[ $2 != "$3" ]]; then
        status="UPDATE AVAILABLE"
        behind=1
    fi
    printf '%-34s %-14s %-14s %s\n' "$1" "${2:0:12}" "${3:0:12}" "$status"
}

latest_release() { # owner/repo
    curl -fsSL --max-time 15 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
        | python3 -c 'import json, sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))' 2>/dev/null || true
}

latest_head() { # owner/repo
    GIT_CONFIG_GLOBAL=/dev/null git ls-remote "https://github.com/$1" HEAD 2>/dev/null | cut -f1 | head -n1 || true
}

printf '%-34s %-14s %-14s %s\n' pin pinned latest status
report neovim "$NVIM_VERSION" "$(latest_release neovim/neovim)"
report fnm "$FNM_VERSION" "$(latest_release Schniz/fnm)"
report uv "$UV_VERSION" "$(latest_release astral-sh/uv)"
report antidote "$ANTIDOTE_REF" "$(latest_head mattmc3/antidote)"
report tpm "$TPM_REF" "$(latest_head tmux-plugins/tpm)"

declare -A seen=()
for list in "$root"/shell/plugins/*.txt; do
    while read -r repo rest; do
        [[ $repo == */* && $rest == *pin:* ]] || continue
        pin=${rest##*pin:}; pin=${pin%% *}
        [[ -z ${seen[$repo@$pin]:-} ]] || continue
        seen[$repo@$pin]=1
        report "$repo" "$pin" "$(latest_head "$repo")"
    done < <(grep -v '^[[:space:]]*#' "$list")
done

if (( behind )); then
    printf '\nSome pins are behind. Bump the pin (and checksum), test, and commit.\n'
    [[ ${1:-} == --fail ]] && exit 1
fi
exit 0
