# whc-theme

Renders the WHC colour themes into terminal, editor and desktop configs. One Python 3 file (`whc-theme`, standard library only) plus theme data.

The canonical copy lives in the brand repo (`tools/whc-theme/`) and reads the palettes straight from `dist/`. The dotfiles vendor a copy with its own `data/` (`just theme-sync` refreshes both), so they never need the brand repo at runtime. Full documentation: the brand repo's `docs/18-theming-tool.md`.

## Themes

| Id | Mode | What |
|---|---|---|
| `meadow-night` | dark | WHC's daily driver: Meadow's Night background, Night Garden accents at one lightness. Re-tinted per machine. |
| `meadow-day` | light | Cream and Ink, every accent ≥ 4.5:1. Re-tinted per machine. |
| `dracula-meadow` | dark | Dracula Pro's recipe on Meadow's hues. Re-tinted per machine. |
| `dracula` | dark | The original free Dracula (what the dotfiles used before). |
| `dracula-pro`, `dracula-pro-blade`, `-buffy`, `-lincoln`, `-morbius`, `-van-helsing` | dark | Dracula Pro Base and its variants. |
| `dracula-pro-alucard` | light | Dracula Pro's light theme. |

Every theme has a variant per machine (bessie, ranch, ship, cowgirl, deborah, felicia, dowager, mermaid, sailor). The bespoke WHC themes re-tint the background, comment and selection. The Dracula themes keep their own background, and only the machine's status segment and cursor take its brand colour.

## Commands

```sh
whc-theme list [--devices]                 # themes
whc-theme targets                          # targets: where each writes, how it is wired (also --list-targets)
whc-theme current                          # what the dotfiles are rendered with, and this machine's state
whc-theme preview [meadow-night|all]       # truecolor preview in this terminal
whc-theme apply meadow-night --dry-run     # what would change
whc-theme apply meadow-night               # render the dotfiles-wired targets
whc-theme apply meadow-night --targets kitty,konsole,walker   # other targets (files outside the dotfiles)
whc-theme export slack --theme meadow-night --variant cowgirl # print one target
whc-theme data-sync --from ~/projects/brand-identity          # refresh the vendored data/
```

In the dotfiles: `just theme <command>` and `just theme-sync`.

## Variants

- `auto` (default): runtime targets (tmux, zsh/p10k/fzf, Neovim, lazygit, Hyprland) contain every machine and choose `$WHC_DEVICE` (else the short hostname) when they load, so one committed file serves every machine. Shared dotfiles files that can't branch (foot, mako, Termux) get the device-neutral base. Inside tmux the pane background still takes the machine's tint, because tmux sets `window-style`. Everything else (kitty, Konsole, Walker and so on) gets this machine's variant.
- `base`: device-neutral everywhere.
- `<machine>`: that machine everywhere, with the runtime targets pinned to it.

## State

- `<dotfiles>/whc-theme/theme.toml` (committed): the theme the repo's generated files were rendered with.
- `${XDG_STATE_HOME:-~/.local/state}/whc/theme.toml` (per machine): what was last applied here, when, and which targets. Override the path with `WHC_THEME_STATE`.
- Environment: `WHC_DEVICE` (machine), `WHC_DOTFILES_DIR` (dotfiles root), `WHC_THEME_DATA` (data dir). The generated files export `WHC_THEME` (the theme id) to shells and tmux.

## Tests

```sh
python3 -B -m unittest discover -s tools/whc-theme -p 'test_*.py'   # brand repo
python3 -B -m unittest discover -s whc-theme -p 'test_*.py'         # dotfiles (part of `just test`)
```

`build_dracula.py` (brand repo only) rebuilds `dist/whc-theme/dracula.json` from `tools/terminal/common.py`. `build_examples.py` writes example renders of the targets that aren't wired into the dotfiles to `dist/whc-theme/examples/`.
