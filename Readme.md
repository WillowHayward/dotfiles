These are the dotfiles I use to make my dev experience more universal across devices.

# Usage

Install Git and a module-capable version of [just](https://github.com/casey/just), then clone this repository to `~/dotfiles` (shell and scripts use `$WHC_DOTFILES_DIR`, defaulting to that path). Without `just`, run the same tasks with `setup/setup.sh <task>`.

Initialize the machine identity once, then run every setup task the machine's profile includes:

```sh
just setup init-system
just setup all
```

`init-system` prompts for the profile and device name, then writes them to `/etc/environment` using sudo. Log out and back in to expose the values to every process. Setup commands and zsh read the file directly, so `setup all` can be run immediately afterward. Use `just setup` to list the smaller setup recipes.

## Profiles

`WHC_PROFILE` is the machine's role. Each profile adds to the one below it:

| Profile | Environment | What it gets |
|---|---|---|
| `remote` | Debian family, servers | The lightweight baseline: zsh with Antidote, the Dracula prompt and autosuggestions, fzf, tmux, Git config, and plain Vim. No Neovim, Node, Taskwarrior or desktop. |
| `work` | Debian family, WSL | `remote` plus the developer tooling: Neovim 0.11+, fnm/Node, lazygit, build tools, Taskwarrior and tmux project layouts. |
| `home` | Arch Linux | `work` plus the Hyprland desktop (`just setup desktop`): Hyprland, Walker/Elephant, Flameshot, swayimg, mime handlers. Login and lock-screen configuration stays opt-in (`just setup manual-lock`). |

Code that needs a tier checks `WHC_DEV` (home and work) or `WHC_DESKTOP` (home) rather than comparing profile names. In zsh the layers are `shell/zsh/core/` (every profile), `shell/zsh/dev/` (home and work) and `shell/zsh/profile/<profile>.zsh`. Put private, machine-specific shell settings in `shell/zsh/profile/<profile>.local.zsh`, which is not tracked. Git has the same split: `git/profile/<profile>.gitconfig` is linked to `~/.gitconfig.profile`, and an untracked `~/.gitconfig.local` is the place for per-machine settings such as a work email address.

Connection context is separate from the machine role: SSH sessions set `WHC_REMOTE` even on a `home` or `work` machine, and non-SSH sessions set `WHC_LOCAL`.

On a new server, `scripts/create-user.sh` (run as root) creates a login user with zsh, sudo and an SSH key.

## Testing

`just check` validates `just`, shell, zsh and Python syntax, and `just test` adds the hermetic setup tests (fake `/etc/environment`, fake os-release, shimmed package managers) and the project-picker unit tests. `just test-container remote` or `just test-container work` runs that profile's real setup in a throw-away Debian container (needs docker and network) and checks that zsh, git and, for `work`, Neovim start cleanly on a first run; `just test-container home` checks that every Arch package name resolves.

## Environment variables

Create a `.env` file in the root of this repo for non-identity variables, using `.env.example` as a reference. `WHC_PROFILE` and `WHC_DEVICE` are managed in `/etc/environment`, not `.env`.

Set up automatically occurs in .zshrc

## Directory shortcuts

| Command | Goes to | Root variable (default) |
|---|---|---|
| `cdd [name]` | the dotfiles repo, or one of its immediate subdirectories | `WHC_DOTFILES_DIR` (`~/dotfiles`) |
| `cdp [name]` | the projects directory, or one of its immediate subdirectories | `WHC_PROJECTS_DIR` (`~/projects`) |
| `cdi [name]` | the infra directory, or one of its immediate subdirectories | `WHC_INFRA_DIR` (`~/infra`) |

Tab completion offers the immediate subdirectories (hidden ones once you type a dot), and nested paths such as `cdp app/src` are rejected. `WHC_PROJECTS_DIR` and `WHC_INFRA_DIR` can be overridden in `.env`; `WHC_DOTFILES_DIR` has to be exported before the shell starts because `.env` lives inside it. The tmux project picker uses the same variables.

## Terminal appearance

Tmux uses Neovim's Dracula palette with a compact session/window bar. Zsh loads the official [Dracula Powerlevel10k theme](https://github.com/dracula/powerlevel10k) through Antidote, including its two-line layout, icons, Git status, and right-side status segments. The configuration uses explicit Dracula RGB colours so it does not depend on the terminal ANSI palette. The adapted upstream theme lives in `shell/themes/dracula-powerlevel10k/p10k.zsh`; local integration and the red remote-device segment live in `shell/zsh/prompt.zsh`. The theme has no trailing prompt arrow. Use a Nerd Font for its icons and Powerline separators.

The `remote` profile shows `WHC_DEVICE` in a red Powerline segment. SSH sessions also show this segment automatically. An empty device name falls back to the short hostname. Local sessions with other profiles omit the segment.

Open a new shell to load the prompt, or run `source "$WHC_DOTFILES_DIR/shell/zsh/core/prompt.zsh"` in an existing shell. Reload tmux with `tmux source-file ~/.tmux.conf`. The true-color terminal setting applies to new panes.

## Symlinks

`just setup links` creates the links for the machine's profile. Existing correct links are accepted; conflicting files or links are reported and never replaced.

| dotfile | System location | Profiles | Description |
|---|---|---|---|
| shell/.zshrc | ~/.zshrc | all | Loader for the layered zsh config in `shell/zsh/` |
| git/.gitconfig | ~/.gitconfig | all | Global git settings: identity, aliases, pager with a fallback when diff-so-fancy is missing |
| git/profile/\<profile\>.gitconfig | ~/.gitconfig.profile | all | Per-profile git settings (SSH URL rewriting is off on `remote`) |
| git/.gitignore.global | ~/.gitignore.global | all | Global git ignore, set up in the .gitconfig |
| shell/.tmux.conf | ~/.tmux.conf | all | Tmux settings, using [TPM](https://github.com/tmux-plugins/tpm) |
| shell/.tmux.session.conf | ~/.tmux.session.conf | home, work | Project pane layout (`prefix M`) |
| vim/.vimrc | ~/.vimrc | all | A basic Vim config |
| nvim/ | ~/.config/nvim | home, work | Neovim config |
| node/.npmrc, node/.yarnrc.yml | ~/.npmrc, ~/.yarnrc.yml | home, work | NPM and Yarn settings |
| taskwarrior/.taskrc | ~/.taskrc | home, work | Taskwarrior config |
| hypr/, swayimg/, walker/, misc/ | ~/.config/... | home | The desktop: Hyprland, swayimg (adjacent images, h/l to navigate, scroll to zoom), Walker and Elephant menus, mime handlers and browser flags |

## Hyprland login, locking, and sleep

- `~/.config/hypr` links to `hypr/`, including `hyprlock.conf` and `hypridle.conf`.
- `/etc/greetd/config.toml` links to `greetd/config.toml`; tuigreet launches `start-hyprland`.
- `/etc/systemd/logind.conf.d/60-manual-power.conf` links to `systemd/logind.conf`.
- Run `just setup manual-lock` to install the packages and link the power settings. This recipe requires the `home` profile, and `just setup desktop` is the user-level counterpart that links `~/.config/hypr`. Reboot to apply the logind sandbox change.
- Hyprland starts hypridle. The hardware lock key (`XF86ScreenSaver`) sends `loginctl lock-session` to hypridle, which starts hyprlock.
- The power button suspends, including while locked. Hypridle locks before suspend and waits for the compositor's lock notification.
- No idle listeners are configured, and logind's idle action is disabled.
- Customize the greeter in `greetd/config.toml` and lock-screen appearance in `hypr/hyprlock.conf`.
- Greetd reads the new command on its next service start (normally reboot); do not restart it during an active desktop session.

Reference: https://wiki.hypr.land/hypr-ecosystem/user/hypridle/

Logind uses `systemd/logind-dotfiles.conf` (linked as a service drop-in) to expose only the dotfiles systemd directory read-only inside its otherwise hidden home directory. Update the absolute path there if relocating the repo.

## tmux project workspaces

- New local terminals attach to `general`, creating it with one pane if needed. `tms` with no arguments does the same.
- `Ctrl-Space`, then `M`: arrange up to four panes as one main area above three equal-width lower areas. Missing panes are added; more than four panes are left untouched. The lower row is 12 lines high when there is room.
- Ordinary new windows remain single-pane. `c`, `n`, `p`, `%`, and `"` after the prefix open windows/splits in the current pane's directory.
- Open Walker (`Super+Return`) and type `#` to browse projects, or `#name` to filter them. You can also search for **Projects**. `just setup desktop` links the Elephant menu and desktop entry; restart Elephant to load the menu. There is no separate project-picker keybind. Walker uses `::` for application arguments so `#` remains available for project search.
- The picker lists directories directly under `~/projects`, plus `~/infra` itself and any of its immediate subdirectories that are Git repositories. `WHC_PROJECTS_DIR` and `WHC_INFRA_DIR` override those roots (see Directory shortcuts).
- A new project session uses the directory's name, four panes, and Neovim in the main pane. Quitting Neovim returns to a shell. Reopening reuses the session without resetting its panes and switches the existing foot/tmux terminal on the current workspace when one is available. Dots/colons become underscores; conflicting names receive a path-derived suffix (`general` is reserved).
- Project Neovim starts Codex in a local Sidekick terminal, initially hidden, without an extra tmux session. Toggle/prompt shortcuts automatically reuse the running context for the current directory. `<leader>as` remains an explicit context picker. `Ctrl+G` or `Alt+Q` hides Sidekick while a command keeps running; `Ctrl+\`, then `Ctrl+N` enters terminal normal mode. Closing Neovim ends its local AI process.
- AI processes use `WHC_AI=true`, `SHELL=/bin/bash`, and per-project Bash history under `${XDG_STATE_HOME:-~/.local/state}/whc-ai/`. Both interactive Bash commands and noninteractive `bash -c` commands use this history; normal zsh history is separate.
- New Neovim instances load the Sidekick changes. Existing tmux panes and sessions are preserved when reloading the config.

## Node.js

[fnm](https://github.com/Schniz/fnm) manages Node versions. Run `just setup node` (home and work) to install fnm when missing and select the latest LTS Node as the default. Zsh initializes fnm before attaching to tmux and automatically switches using `.node-version` or `.nvmrc`, including in parent directories. Launcher-started Neovim and AI Bash commands also load fnm.

Use `fnm install <version>` to install a project version and `fnm use <version>` to switch manually. New shells load the setup; in an existing zsh shell, run `source "$WHC_DOTFILES_DIR/shell/zsh/dev/fnm.zsh"`.
