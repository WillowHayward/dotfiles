bindkey -v # Turn on vim mappings

# Oh My Zsh's vi-mode pastes with `clippaste`, which hands over whatever the Wayland clipboard
# holds, including the PNG bytes of a screenshot. Ask for text only; with none, vi-mode falls
# back to its own buffer.
if [[ -n ${WAYLAND_DISPLAY:-} ]] && (( $+commands[wl-paste] )); then
    clippaste() { wl-paste --no-newline --type text 2>/dev/null; }
fi

