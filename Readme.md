These are the dotfiles I use to make my dev experience more universal across devices.

# Usage

Install Git and a module-capable version of [just](https://github.com/casey/just), then clone this repository. Machine setup is selected by `WHC_PROFILE`: `home` uses Arch Linux, while `work` and `remote` use a Debian-family distribution.

Initialize the machine identity once, then run all core setup tasks:

```sh
just setup init-system
just setup all
```

`init-system` prompts for the profile and device name, then writes them to `/etc/environment` using sudo. Log out and back in to expose the values to every process. Setup commands read the file directly, so `setup all` can be run immediately afterward.

Use `just setup` to list the smaller setup recipes. `setup all` installs the developer package baseline, links dotfiles, and configures zsh, Neovim, tmux, and Node.js. Login/locking and other desktop-specific tools remain opt-in.

## Environment variables

Create a `.env` file in the root of this repo for non-identity variables, using `.env.example` as a reference. `WHC_PROFILE` and `WHC_DEVICE` are managed in `/etc/environment`, not `.env`.

Set up automatically occurs in .zshrc

## Terminal appearance

Tmux uses Neovim's Dracula palette with a compact session/window bar. Zsh loads the official [Dracula Powerlevel10k theme](https://github.com/dracula/powerlevel10k) through Antidote, including its two-line layout, icons, Git status, and right-side status segments. The configuration uses explicit Dracula RGB colours so it does not depend on the terminal ANSI palette. The adapted upstream theme lives in `shell/themes/dracula-powerlevel10k/p10k.zsh`; local integration and the red remote-device segment live in `shell/zsh/prompt.zsh`. The theme has no trailing prompt arrow. Use a Nerd Font for its icons and Powerline separators.

The `remote` profile shows `WHC_DEVICE` in a red Powerline segment. SSH sessions also show this segment automatically. An empty device name falls back to the short hostname. Local sessions with other profiles omit the segment.

Open a new shell to load the prompt, or run `source ~/dotfiles/shell/zsh/prompt.zsh` in an existing shell. Reload tmux with `tmux source-file ~/dotfiles/shell/.tmux.conf`. The true-color terminal setting applies to new panes.

## Symlinks

| dotfile           | System Location         | Description                                                                                                                                                                     |
|-------------------|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| .zshrc            | ~/.zshrc | zsh config - I used https://ohmyz.sh/ as well |
| .gitconfig        | ~/.gitconfig            | Global git settings - this includes my name personal information (name, email) as well as some quality of life settings.                                                        |
| .gitignore.global | ~/.gitignore.global     | Global git ignore - Set up in the .gitconfig.                                                                                                                                   |
| .tmux.conf        | ~/.tmux.conf            | Tmux settings - I use [Tmux Package Manager](https://github.com/tmux-plugins/tpm) so that has to be installed first.                                                            |
| nvim/             | ~/.config/nvim          | My Neovim config |
| swayimg/          | ~/.config/swayimg       | Image viewer: adjacent images, h/l or Left/Right for previous/next, scroll to zoom, hidden info overlay |
| .npmrc            | ~/.npmrc                | NPM settings - Mostly initial project setup things like my name and email, MIT license, version 0.0.1.                                                                          |
| .vimrc            | ~/.vimrc                | A basic Vim config |

To create the profile-appropriate links, run `just setup links`. Existing correct links are accepted; conflicting files or links are reported and never replaced.


## Hyprland login, locking, and sleep

- `~/.config/hypr` links to `hypr/`, including `hyprlock.conf` and `hypridle.conf`.
- `/etc/greetd/config.toml` links to `greetd/config.toml`; tuigreet launches `start-hyprland`.
- `/etc/systemd/logind.conf.d/60-manual-power.conf` links to `systemd/logind.conf`.
- Run `just setup manual-lock` to install the packages and link the power settings. This recipe requires the `home` profile. Reboot to apply the logind sandbox change.
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
- Open Walker (`Super+Return`) and type `#` to browse projects, or `#name` to filter them. You can also search for **Projects**. Install the native Elephant menu and desktop entry with `just tmux-projects`, then restart Elephant to load the menu. There is no separate project-picker keybind. Walker uses `::` for application arguments so `#` remains available for project search.
- The picker lists directories directly under `~/projects`, replacing `infra` with its immediate subdirectories. `WHC_PROJECTS_DIR` can override that root.
- A new project session uses the directory's name, four panes, and Neovim in the main pane. Quitting Neovim returns to a shell. Reopening reuses the session without resetting its panes and switches the existing foot/tmux terminal on the current workspace when one is available. Dots/colons become underscores; conflicting names receive a path-derived suffix (`general` is reserved).
- Project Neovim starts Codex in a local Sidekick terminal, initially hidden, without an extra tmux session. Toggle/prompt shortcuts automatically reuse the running context for the current directory. `<leader>as` remains an explicit context picker. `Ctrl+G` or `Alt+Q` hides Sidekick while a command keeps running; `Ctrl+\`, then `Ctrl+N` enters terminal normal mode. Closing Neovim ends its local AI process.
- AI processes use `WHC_AI=true`, `SHELL=/bin/bash`, and per-project Bash history under `${XDG_STATE_HOME:-~/.local/state}/whc-ai/`. Both interactive Bash commands and noninteractive `bash -c` commands use this history; normal zsh history is separate.
- New Neovim instances load the Sidekick changes. Existing tmux panes and sessions are preserved when reloading the config.

## Node.js

[fnm](https://github.com/Schniz/fnm) manages Node versions. Run `just setup node` to install fnm when missing and select the latest LTS Node as the default. Zsh initializes fnm before attaching to tmux and automatically switches using `.node-version` or `.nvmrc`, including in parent directories. Launcher-started Neovim and AI Bash commands also load fnm.

Use `fnm install <version>` to install a project version and `fnm use <version>` to switch manually. New shells load the setup; in an existing zsh shell, run `source ~/dotfiles/shell/zsh/fnm.zsh`.
