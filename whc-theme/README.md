# whc-theme (vendored)

Renders the WHC colour themes into terminal, editor and desktop configs: one Python 3 file (`whc-theme`, standard library only) plus theme data (`data/`). This is a vendored copy, so the dotfiles never need another repo at runtime.

The canonical home is the private repo [WillowHayward/whc-theme](https://github.com/WillowHayward/whc-theme) (`~/projects/whc-theme`), with the full documentation: themes, variants, every target, state and environment variables. Change the tool there, then `just theme-sync` here copies the script, its tests and its data (from `$WHC_THEME_DIR`, default `~/projects/whc-theme`) and re-renders.

## In the dotfiles

```sh
just theme-apply                  # re-render the committed theme into the dotfiles and this machine's apps
just theme-apply dracula          # switch theme (the original Dracula); `just theme list` shows them all
just theme current                # what is rendered and what was applied on this machine
just theme targets                # every target, where it writes, how it is wired
just theme-sync                   # refresh this copy from ~/projects/whc-theme, then re-render
```

`just theme <args>` runs the vendored script with any arguments (`just theme preview all`, `just theme export slack`).

- **Committed targets** (rendered into this repo, one render for every machine): foot, mako, Termux (device-neutral base), and tmux, zsh/p10k/fzf, lazygit, Neovim and Hyprland borders, which pick the machine from `WHC_DEVICE` (else the short hostname) when they load.
- **Machine targets** (`--targets machine`, outside the repo, applied by `just theme-apply` and `just setup desktop` when the app is installed): gsettings colour scheme and accent for GTK 4, Walker's `~/.config/walker/themes/whc/style.css`, Firefox's `userChrome.css`/`userContent.css`/`user.js` in each used profile, and Konsole's scheme, `WHC` profile and default.
- `whc-theme/theme.toml` records the theme the committed files were rendered with; `~/.local/state/whc/theme.toml` what was last applied on this machine.

Tests: `python3 -B -m unittest discover -s whc-theme -p 'test_*.py'` (part of `just test`).
