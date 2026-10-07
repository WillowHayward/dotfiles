These are the dotfiles I use to make my dev experience more universal across devices.

# Usage

Install Git and a module-capable version of [just](https://github.com/casey/just), then clone this repository to `~/dotfiles` (shell and scripts use `$WHC_DOTFILES_DIR`, defaulting to that path). Without `just`, run the same tasks with `setup/setup.sh <task>`.

Initialize the machine identity once, then run every setup task the machine's profile includes:

```sh
just setup init-system
just setup all
```

`init-system` prompts for the profile and device name, then writes them to `/etc/environment` using sudo (in Termux, which has no root, to `$PREFIX/etc/environment`). Device-name presets come from an untracked `setup/devices.local` (one name per line); without it, type a name. Log out and back in to expose the values to every process. Setup commands and zsh read the file directly, so `setup all` can be run immediately afterward. `just --list` shows every recipe and `just setup` the setup tasks.

## First run on a new machine

1. **SSH key.** `ssh-keygen -t ed25519`, add the public key to GitHub, and `ssh-add`. Fetching and cloning use https (so bootstrap works without a key); *pushing* goes over SSH. On `home`, commits are signed with `~/.ssh/id_ed25519.pub` (`just setup ssh` creates `~/.ssh/allowed_signers` once the key exists), and on `home` and `work` `gh auth login` provides the credentials for private https clones.
2. **Work email (work profile).** Put `WHC_WORK_EMAIL=you@company.example` in `.env`. The shell writes it to `~/.cache/whc/gitconfig.work`, which `git/profile/work.gitconfig` includes. **It applies to every repository on the work machine**, personal ones included; override a single repo with `git config --local user.email ...`.
3. **Agents (work profile).** Copilot is the agentic tool there: `npm install -g @github/copilot`, then `copilot` once to sign in. On `home`, Codex comes with the ChatGPT app and Claude Code from its installer. (Copilot *completion* works on both after `:Copilot auth` in Neovim.)
4. **Atuin (optional).** `atuin register` or `atuin login` to sync shell history between machines; nothing is synced until you do.
5. `just setup doctor` reports anything still missing.

## First run on a phone (Termux)

Install [Termux](https://termux.dev) from F-Droid or its GitHub releases, together with **Termux:API**, **Termux:Boot** and **Termux:Widget** from the same source (builds from different sources cannot share permissions; the Play Store build is a separate, limited one). Exempt Termux from battery optimisation so sshd survives Doze, and open Termux:Boot once so Android lets it run at start-up.

```sh
pkg install git just
git clone https://github.com/WillowHayward/dotfiles ~/dotfiles && cd ~/dotfiles
just setup init-system   # mobile for a daily phone, remote for a test device
just setup all           # includes `just setup termux`
termux-setup-storage     # optional: shared storage (Downloads, the Obsidian vault) at ~/storage
```

Then restart Termux. `just setup termux` links the Dracula colours and `termux.properties` (two rows of extra keys: `PFX` sends the tmux prefix, the back button is Escape), installs a pinned JetBrains Mono Nerd Font, installs the **ssh** widget shortcut (pick a host from `~/.ssh/config.d`, attach its `general` tmux session over mosh when possible) and a Termux:Boot script that starts termux-services. Once `~/.ssh/authorized_keys` exists, rerunning it turns password logins off and enables sshd on port 8022. A `remote` phone also holds a wake lock at boot so it stays reachable; a `mobile` one does not, to save battery.

Each phone signs commits with its own key: add that key to GitHub as a signing key, and to `~/.ssh/allowed_signers` on the other machines.

## Profiles

`WHC_PROFILE` is the machine's role. Each profile adds to the one below it:

| Profile | Environment | What it gets |
|---|---|---|
| `remote` | Debian family, servers; Termux on a test phone | The lightweight baseline: zsh with Antidote, the Dracula prompt, autosuggestions and syntax highlighting, fzf, zoxide, atuin, delta, tmux, Git config, plain Vim (with Ctrl-hjkl pane navigation), a server comfort suite (htop, ncdu, rsync, jq, tree, fd, bat, eza), Docker (`just setup docker`), an SSH defaults include and a login banner. No Neovim, Node, Taskwarrior or desktop. |
| `work` | Debian family, WSL | `remote` plus the developer tooling: Neovim 0.11+, fnm/Node, uv, direnv, lazygit, gh, shellcheck, Taskwarrior, build tools and tmux project layouts. WSL templates with `just setup wsl`. |
| `mobile` | Termux (Android), a daily phone | `remote`'s baseline (without Docker) plus the developer tooling, all from `pkg`: Neovim, Node LTS, uv, tree-sitter with clang, direnv, lazygit, gh, shellcheck, Taskwarrior. No AI tools (drive the workstation's agents instead) and no Godot. |
| `home` | Arch Linux | `work` plus the Hyprland desktop (`just setup desktop`): Hyprland, Walker/Elephant, Flameshot, foot, mako, swayimg, mime handlers. Login and lock-screen configuration stays opt-in (`just setup manual-lock`). Godot tooling. |

Code that needs a tier checks `WHC_DEV` (home, work and mobile) or `WHC_DESKTOP` (home) rather than comparing profile names. The platform is separate from the profile: Termux sets `WHC_TERMUX` in zsh and `PACKAGE_FAMILY=termux` in setup, and gets the Termux settings whatever its profile. In zsh the layers are `shell/zsh/core/` (every profile), `shell/zsh/dev/` (home, work and mobile) and `shell/zsh/profile/<profile>.zsh`. Put private, machine-specific shell settings in `shell/zsh/profile/<profile>.local.zsh`, which is not tracked. Git has the same split: `git/profile/<profile>.gitconfig` is linked to `~/.gitconfig.profile`, and an untracked `~/.gitconfig.local` is the place for per-machine settings.

Connection context is separate from the machine role: SSH sessions set `WHC_REMOTE` even on a `home` or `work` machine, and non-SSH sessions set `WHC_LOCAL`.

On a new server, `scripts/create-user.sh` (run as root) creates a login user with zsh, sudo and an SSH key; `just setup harden` then tightens sshd, automatic updates and the firewall (it asks before each change, and is a candidate to move into the infra repo).

## Setup tasks

| Task | Does |
|---|---|
| `init-system` | Write `WHC_PROFILE` and `WHC_DEVICE` to `/etc/environment` (`$PREFIX/etc/environment` in Termux) |
| `packages [--list\|--diff]` | Install the profile's packages; `--list` prints the manifest, `--diff` shows packages installed outside it |
| `links [--relink\|--adopt]` | Link the profile's dotfiles. Strict by default; `--relink` replaces wrong symlinks, `--adopt` also moves real files to `~/.local/state/whc/backups/` |
| `shell`, `tmux`, `nvim`, `node`, `python` | Zsh and Antidote; tmux and TPM; Neovim; fnm and Node (plus the tree-sitter CLI); uv |
| `ssh`, `bash` | Add an `Include` to `~/.ssh/config` (per-host files in `~/.ssh/config.d/`, shared defaults last) and a source line to `~/.bashrc`, without replacing either file |
| `docker`, `harden` | Docker Engine from Docker's apt repository; sshd/updates/firewall hardening (remote) |
| `wsl` | Install `work/wsl.conf` and the Windows-side `.wslconfig` template (work, WSL) |
| `termux` | Termux colours, keys and font, the widget shortcut, the boot script and key-only sshd (Termux) |
| `desktop`, `manual-lock` | Hyprland packages and links; greetd and logind (home) |
| `doctor` | Missing tools, wrong links, lockfile drift, stale hand-built desktop binaries |
| `all` | Everything the profile includes (`manual-lock`, `harden` and `wsl` stay explicit) |

Every download is pinned and checksummed in `setup/pins.env` (Neovim, fnm, uv, tree-sitter CLI, Antidote, TPM) or by commit in `shell/plugins/*.txt`. `just updates` compares all pins with upstream and `just update` pulls, updates TPM plugins, moves fnm to the latest LTS and syncs Neovim.

## Testing

`just check` validates `just` (including that every recipe has a doc comment), shell, zsh and Python syntax, and runs shellcheck when installed. `just test` adds the hermetic setup tests (fake `/etc/environment`, fake os-release, shimmed package managers), the zsh loader tests, a stub-based load of the Hyprland config that fails on an undescribed bind, and the project-picker unit tests. `just test-container remote` or `just test-container work` runs that profile's real setup in a throw-away Debian container (needs docker and network) and checks that zsh, git and, for `work`, Neovim start cleanly on a first run; `just test-container home` checks that every Arch package name resolves. CI runs all of this, plus a history-wide secret scan, on every push. A pre-commit hook (enabled by `just setup links`) runs gitleaks on staged changes and `just check`.

## Environment variables

Create a `.env` file in the root of this repo for non-identity variables, using `.env.example` as a reference. `WHC_PROFILE` and `WHC_DEVICE` are managed in `/etc/environment`, not `.env`. `.env` is sourced by `.zshrc` (see `shell/zsh/core/env.zsh`).

## Directory shortcuts

| Command | Goes to | Root variable (default) |
|---|---|---|
| `cdd [name]` | the dotfiles repo, or one of its immediate subdirectories | `WHC_DOTFILES_DIR` (`~/dotfiles`) |
| `cdp [name]` | the projects directory, or one of its immediate subdirectories | `WHC_PROJECTS_DIR` (`~/projects`) |
| `cdi [name]` | the infra directory, or one of its immediate subdirectories | `WHC_INFRA_DIR` (`~/infra`) |

Tab completion offers the immediate subdirectories (hidden ones once you type a dot), and nested paths such as `cdp app/src` are rejected. `WHC_PROJECTS_DIR` and `WHC_INFRA_DIR` can be overridden in `.env`; `WHC_DOTFILES_DIR` has to be exported before the shell starts because `.env` lives inside it. The tmux project picker uses the same variables. `z <partial>` (zoxide) jumps to any directory you have visited, `zi` picks with fzf.

## Shell

- **Loading:** `.zshrc` sources `core/`, then `dev/` where `WHC_DEV` is set, then the profile file. Local terminals hand over to tmux right after the environment and `PATH` are set, so the full init runs once, inside tmux.
- **Plugins:** `shell/plugins/{early,core,dev,last}.txt`, every one pinned to a commit; bundles are cached under `~/.cache/whc/`. `just zsh-refresh` forgets the caches (and the completion dump, which is otherwise rebuilt daily).
- **History:** Ctrl-R is Atuin when installed, otherwise fzf. fzf uses `fd` and the Dracula colours.
- **direnv:** `use_fnm` in a project's `.envrc` puts its Node version on `PATH`; `direnv allow` approves a file.
- **Remote logins:** SSH logins on a `remote` machine print a banner from `shell/motd.d/*.zsh` (device, uptime/load/memory/disk, containers). Add a numbered file there to add a segment; `WHC_MOTD=0` silences it.
- **Not tracked:** `shell/zsh/profile/<profile>.local.zsh` (personal aliases, hosts), `~/.gitconfig.local`, `.env`.

## Git

`git/.gitconfig` is shared; `git/profile/<profile>.gitconfig` adds the profile's part. Pulls rebase (with auto-stash), fetches prune, conflicts use `zdiff3`, `rerere` remembers resolutions, and diffs go through [delta](https://github.com/dandavison/delta) when installed. On `home` and `work`, `https://github.com/` URLs are only rewritten for *pushes*; fetch and clone stay on https so a machine without a key can bootstrap. On `home`, commits are signed with the SSH key: GitHub shows "Verified", and `git log --show-signature` verifies locally through `~/.ssh/allowed_signers`. Signing is off on `work` until a key exists there (add `[commit] gpgsign = true` to `~/.gitconfig.local`).

## Terminal appearance

Tmux uses Neovim's Dracula palette with a compact session/window bar. Zsh loads the official [Dracula Powerlevel10k theme](https://github.com/dracula/powerlevel10k) through Antidote, including its two-line layout, icons and Git status. The configuration uses explicit Dracula RGB colours so it does not depend on the terminal ANSI palette. The adapted upstream theme lives in `shell/themes/dracula-powerlevel10k/p10k.zsh`; local integration lives in `shell/zsh/core/prompt.zsh`. Use a Nerd Font (the `home` desktop installs the symbols fallback) for its icons.

The first prompt segment is the machine prefix: the OS logo and `WHC_DEVICE` (short hostname if unset); a local shell on `home` shows just the logo. It is in the theme's muted blue everywhere except `remote` machines and SSH sessions, where it is **vibrant red** (and so is the tmux session pill). A very small bash fallback (`just setup bash`) shows a red `[device]` prefix in the same situations.

Open a new shell to load the prompt, or run `source "$WHC_DOTFILES_DIR/shell/zsh/core/prompt.zsh"` in an existing shell. Reload tmux with `tmux source-file ~/.tmux.conf`.

## Symlinks

`just setup links` creates the links for the machine's profile. Existing correct links are accepted; conflicting files or links are reported and never replaced (see `--relink` and `--adopt` above).

| dotfile | System location | Profiles | Description |
|---|---|---|---|
| shell/.zshrc | ~/.zshrc | all | Loader for the layered zsh config in `shell/zsh/` |
| git/.gitconfig | ~/.gitconfig | all | Global git settings |
| git/profile/\<profile\>.gitconfig | ~/.gitconfig.profile | all | Per-profile git settings |
| git/.gitignore.global | ~/.gitignore.global | all | Global git ignore |
| shell/.tmux.conf | ~/.tmux.conf | all | Tmux settings, using [TPM](https://github.com/tmux-plugins/tpm) |
| shell/.tmux.session.conf | ~/.tmux.session.conf | home, work, mobile | Project pane layout (`prefix M`) |
| vim/.vimrc | ~/.vimrc | all | Vim config, with Ctrl-hjkl navigation across splits and tmux panes |
| atuin/config.toml | ~/.config/atuin/config.toml | all | Shell history |
| nvim/ | ~/.config/nvim | home, work, mobile | Neovim config (see below) |
| node/.npmrc, node/.yarnrc.yml | ~/.npmrc, ~/.yarnrc.yml | home, work, mobile | NPM and Yarn settings |
| taskwarrior/.taskrc | ~/.taskrc | home, work, mobile | Taskwarrior config |
| direnv/, lazygit/ | ~/.config/direnv, ~/.config/lazygit | home, work, mobile |
| termux/termux.properties, termux/colors.properties | ~/.termux/ | Termux | Extra keys and settings; Dracula colours. The shortcut and boot script are installed as copies (see the Termux section) | direnv helpers; lazygit with delta |
| hypr/, swayimg/, walker/, foot/, mako/, gtk-3.0/, gtk-4.0/, xdg-desktop-portal/, misc/, systemd/user/ | ~/.config/... | home | The desktop |

## Neovim

`nvim/lua/whc/` is the editor (options, keymaps, profile, project helpers, agent sessions); `nvim/lua/plugins/` holds one lazy.nvim spec file per topic, and each plugin's keymaps are in its spec so it loads on first use. `whc/profile.lua` gates features by profile: Godot on `home`; agent tools Codex and Claude on `home`, Copilot on `work`. Copilot suggestions feed `blink.cmp` on both. Formatting is `conform.nvim` (on save, falling back to the language server), linting `nvim-lint` plus Ruff, and parsers come from nvim-treesitter (needs the tree-sitter CLI, which setup provides). Telescope is the picker (Ctrl-n/p move, Ctrl-u/d scroll the preview), `\` opens Oil in a float, `<leader>R` renames the file, and `2<leader>h` goes two tabs left. Git is `<leader>g`: hunks (gitsigns: `gs` stage, `gr` reset, `gp` preview), `gn` Neogit, `gd`/`gh`/`gH` Diffview (also the merge tool), `gg` lazygit through Snacks (themed from the colour scheme, files open in the running Neovim; `gF`/`gL` its logs), `gx` opens the line on GitHub, `gb`/`gl` pickers. Tests are `<leader>n` (Jest and cargo). Spell checking uses `en_au` with a tracked word list (`nvim/spell/en.utf-8.add`); Neovim offers to download the dictionary the first time it is needed. `just nvim-update` syncs plugins and smoke-tests; `just keybinds nvim` lists the mappings.

## Hyprland login, locking, and sleep

- `~/.config/hypr` links to `hypr/`, including `hyprlock.conf` and `hypridle.conf`. Every bind carries a description: `just keybinds hypr` prints them. Per-device settings (the game monitor) live in `hypr/devices/<WHC_DEVICE>.lua`; personal rules go in the untracked `hypr/local.lua`; HyprMon's generated `hyprmon.lua` owns the monitor layout.
- `just setup manual-lock` installs the packages and **copies** (not symlinks) the system files: greetd's config is rendered from `greetd/config.toml.in` with the installing user and the session launcher, and `systemd/logind.conf` is copied to `/etc/systemd/logind.conf.d/60-manual-power.conf`. Rerun it to apply edits. Root-owned files no longer point into `$HOME`, so logind's sandbox needs no workaround.
- The greeter launches `uwsm start hyprland.desktop` when uwsm is installed (a systemd-managed session, so `graphical-session.target` is active), otherwise `start-hyprland`. If login fails, switch to a TTY and run `WHC_NO_UWSM=1 just setup manual-lock`.
- This recipe requires the `home` profile, and `just setup desktop` is the user-level counterpart. Reboot to apply.
- Hyprland starts hypridle. The hardware lock key (`XF86ScreenSaver`) sends `loginctl lock-session` to hypridle, which starts hyprlock.
- The power button suspends, including while locked. Hypridle locks before suspend and waits for the compositor's lock notification. No idle listeners are configured, and logind's idle action is disabled.
- `Super+M` and the Walker session menu both run `hypr-exit`. Print copies a screenshot to the clipboard; Shift+Print also saves it under `~/Pictures/Screenshots`.
- Walker prefixes: ours are `#` projects, `+` Bluetooth devices (connect, trust, remove) and `&` audio devices; Walker's own defaults add `:` clipboard history, `@` web search, `>` run a command, `/` files, `.` symbols, `=` calculator, `!` todo, `$` windows, `;` the provider list. The defaults are matched first, so a prefix of ours must use a character they leave free. The connectivity menu has Wi-Fi and airplane mode (it is in the default list: type "Wi-Fi").
- Customizing Walker and Elephant: Walker's settings are `walker/config.toml` (tracked, merged over `/etc/xdg/walker/config.toml`). Per-provider settings and data live in Elephant's own files, which are **not tracked**, so they are private by default: `elephant generate config <provider>` writes `~/.config/elephant/<provider>.toml` (for example `websearch.toml` for search engines and their prefixes, `bookmarks.toml`, `snippets.toml`), and your own menus can sit next to the linked ones in `~/.config/elephant/menus/` (reachable from the `;` provider list without any prefix). Walker itself has no include mechanism, so a private *prefix* is the one thing that cannot be kept out of `walker/config.toml`; put private things behind an Elephant menu instead.
- Customize the greeter in `greetd/config.toml.in` and lock-screen appearance in `hypr/hyprlock.conf`. Greetd reads the new command on its next service start (normally reboot); do not restart it during an active desktop session.

Reference: https://wiki.hypr.land/hypr-ecosystem/user/hypridle/

## tmux project workspaces

- New local terminals attach to `general`, creating it with one pane if needed. `tms` with no arguments does the same.
- `Ctrl-Space`, then `M`: arrange up to four panes as one main area above three equal-width lower areas. Missing panes are added; more than four panes are left untouched. The lower row is 12 lines high when there is room.
- Ordinary new windows remain single-pane. `c`, `n`, `p`, `%`, and `"` after the prefix open windows/splits in the current pane's directory.
- Open Walker (`Super+Return`) and type `#` to browse projects, or `#name` to filter them. You can also search for **Projects**. `just setup desktop` links the Elephant menu and desktop entry; restart Elephant to load the menu. There is no separate project-picker keybind. Walker uses `::` for application arguments so `#` remains available for project search.
- Run `pp` for the same list in terminal `fzf`, or `pp <project>` to open a displayed label, unique basename, or path. Zsh completes project names. Outside tmux, `pp` attaches in the current terminal; Walker retains its focus-or-spawn Foot behaviour.
- The picker lists the directories directly under `~/projects`, the dotfiles repo, and `~/infra` as one option; once `~/infra` contains a `.whc` file, the workspace roots it declares are listed too. `WHC_PROJECTS_DIR` and `WHC_INFRA_DIR` override those roots (see Directory shortcuts).
- A new project session uses the directory's name, four panes, and Neovim in the main pane. Quitting Neovim returns to a shell. Reopening reuses the session without resetting its panes and switches the existing foot/tmux terminal on the current workspace when one is available. Stable identity lives in `@project-root`, so the visible name can change safely. Dots/colons become underscores; conflicting names receive a path-derived suffix (`general` is reserved).
- Per-project `.whc` and `.ticket` files are globally ignored. `.whc` is TOML and may define `session`, a fallback `ticket`, and explicit Neovim workspace roots. `.ticket` overrides the fallback. Templates support `{{ project }}`, `{{ ticket }}`, and `{{ branch }}`. Opening a project refreshes its name; use `pp --refresh [project]` after changing a ticket or branch in an already-open session.

  ```toml
  session = "Foo - {{ ticket }}"
  ticket = "TK-1234"

  [workspace]
  roots = ["api", "web", "common"]
  ```

- `<C-t>`, `<leader>/`, and `<leader>*` search the project root plus every configured workspace root. Explicit roots expose independently cloned, superproject-ignored repositories while retaining each repository's own ignore rules. `<leader>gf` remains scoped to the current Git repository.
- The right of the status bar shows AI usage and the battery (`scripts/status-line.py`, cached): on `home` the remaining 5-hour/weekly percentages for Codex (read from its session logs) and Claude (from Anthropic's OAuth usage endpoint, using the token Claude Code stores in `~/.claude/.credentials.json`: read-only, sent only to `api.anthropic.com`, never cached or printed; `WHC_CLAUDE_USAGE_CMD` overrides it); on `work` Copilot's remaining AI credits and percentage used (via `gh`); nothing on `remote`. `prefix C` clears the panes of the window that are waiting at a shell prompt, leaving Neovim, agents and servers alone.
- Inside Neovim, `<leader>fP` picks a project from the same list and switches the tmux client to it.
- `prefix s` opens SessionX for fuzzy switching, previews, renaming, and deleting live sessions. SessionX replaces tmux-resurrect; install or update TPM plugins with `prefix I` after setup or a plugin change.
- Project Neovim starts the profile's default agent (Codex on home, Copilot on work) in a local Sidekick terminal, initially hidden, without an extra tmux session. Toggle/prompt shortcuts automatically reuse the running context for the current directory; `<leader>as` is an explicit context picker, `<leader>ac` toggles Claude on home and `<leader>aT` switches the default tool. `Ctrl+G` or `Alt+Q` hides Sidekick while a command keeps running; `Ctrl+\`, then `Ctrl+N` enters terminal normal mode. Closing Neovim ends its local AI process.
- AI processes use `WHC_AI=true`, `SHELL=/bin/bash`, and per-project Bash history under `${XDG_STATE_HOME:-~/.local/state}/whc-ai/`. Both interactive Bash commands and noninteractive `bash -c` commands use this history; normal zsh history is separate.
- New Neovim instances load the Sidekick changes. Existing tmux panes and sessions are preserved when reloading the config.

## Node.js and Python

[fnm](https://github.com/Schniz/fnm) manages Node versions. In Termux, Node LTS and uv come from `pkg` instead (fnm's builds do not run on Android). Elsewhere, run `just setup node` (home and work) to install fnm when missing and select the latest LTS Node as the default. Zsh switches automatically using `.node-version` or `.nvmrc`, including in parent directories. Launcher-started Neovim and AI Bash commands also load fnm. Use `fnm install <version>` to install a project version and `fnm use <version>` to switch manually; in an existing zsh shell, run `source "$WHC_DOTFILES_DIR/shell/zsh/dev/fnm.zsh"`.

[uv](https://docs.astral.sh/uv/) (`just setup python`) manages Python tools and virtual environments: `uv tool install <tool>`, `uv venv`.

## What the dotfiles do not contain

Back these up separately (restic, or your usual routine); none of it is, or should ever be, in this repository: `.env`, `~/.ssh/` (keys, host files), the age key used by SOPS, `~/.config/gh/hosts.yml`, the Bitwarden/rbw configuration, browser profiles, the Atuin key (`~/.local/share/atuin`), `~/.zsh_history`, and anything under `*.local.zsh`, `~/.gitconfig.local` or `hypr/local.lua`.
