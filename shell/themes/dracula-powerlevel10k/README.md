# Dracula for Powerlevel10k

Source: https://github.com/dracula/powerlevel10k
Revision: `311d00d3600133e4b998f25998cdfd122d8f1e52`

`p10k.zsh` is based on upstream `files/.p10k.zsh`, with terminal colour indexes
replaced by explicit RGB values from the [Dracula palette](https://github.com/dracula/dracula-theme#color-palette).
This makes the prompt independent of the terminal ANSI palette: purple directories,
green Git branches, pink runtime segments, and muted blue OS/time segments.
The frame, Git formatter, status colours, and optional segments use the same palette.
The upstream MIT license is included in `LICENSE`.

`shell/zsh/prompt.zsh` loads this configuration before Antidote loads
Powerlevel10k, then adds the remote-device segment and disables instant prompt
for compatibility with this shell's startup. The upstream sample `.zshrc`
is not needed because Antidote already loads Powerlevel10k.

To update, copy `files/.p10k.zsh` from the upstream repository over `p10k.zsh`,
refresh the license, and record the new revision here. Reapply the RGB colour
changes (including prompt escapes in the frame and Git formatter, and explicit
VCS foregrounds) before using the updated file; upstream still uses indexed colours.
