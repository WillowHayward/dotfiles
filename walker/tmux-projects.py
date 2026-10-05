#!/usr/bin/env python3
"""Shared project picker, metadata, and tmux workspace management."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import tomllib


def tmux(*args, check=True):
    return subprocess.run(["tmux", *args], text=True, capture_output=True, check=check)


def dotfiles_dir():
    return Path(os.environ.get("WHC_DOTFILES_DIR") or Path.home() / "dotfiles").expanduser()


def projects(root, infra):
    entries = [p for p in root.iterdir() if p.is_dir() and not p.name.startswith(".")] if root.is_dir() else []
    if infra.is_dir():
        entries.append(infra)
        entries += [p for p in infra.iterdir()
                    if p.is_dir() and not p.name.startswith(".") and (p / ".git").exists()]
    dotfiles = dotfiles_dir()
    if dotfiles.is_dir() and dotfiles.resolve() not in {p.resolve() for p in entries}:
        entries.append(dotfiles)
    return sorted(entries, key=lambda p: (p.resolve() != dotfiles.resolve(),
                                          project_label(p, root).casefold()))


def project_label(directory, root):
    if directory.resolve() == dotfiles_dir().resolve():
        return "dotfiles"
    if directory.is_relative_to(root):
        return str(directory.relative_to(root))
    if directory.is_relative_to(Path.home()):
        return "~/" + str(directory.relative_to(Path.home()))
    return str(directory)


def project_roots():
    root = Path(os.environ.get("WHC_PROJECTS_DIR") or Path.home() / "projects").expanduser()
    infra = Path(os.environ.get("WHC_INFRA_DIR") or Path.home() / "infra").expanduser()
    return root, infra


def find_config_root(directory):
    """Find the nearest .whc without letting a nested Git repository stop the walk."""
    current = directory.expanduser().resolve(strict=True)
    if current.is_file():
        current = current.parent
    for candidate in (current, *current.parents):
        if (candidate / ".whc").is_file():
            return candidate
    configured = os.environ.get("WHC_PROJECT_ROOT")
    if configured:
        configured_root = Path(configured).expanduser().resolve(strict=True)
        if current == configured_root or configured_root in current.parents:
            return configured_root
    return current


def load_metadata(directory):
    root = find_config_root(directory)
    config_path = root / ".whc"
    config = {}
    if config_path.is_file():
        try:
            config = tomllib.loads(config_path.read_text())
        except (OSError, tomllib.TOMLDecodeError) as exc:
            raise ValueError(f"Cannot read {config_path}: {exc}") from exc
        if not isinstance(config, dict):
            raise ValueError(f"{config_path} must contain a TOML table.")

    session = config.get("session")
    configured_ticket = config.get("ticket")
    if session is not None and not isinstance(session, str):
        raise ValueError(f"session in {config_path} must be a string.")
    if configured_ticket is not None and not isinstance(configured_ticket, str):
        raise ValueError(f"ticket in {config_path} must be a string.")

    ticket = configured_ticket
    ticket_path = root / ".ticket"
    if ticket_path.is_file():
        try:
            ticket = ticket_path.read_text().strip()
        except OSError as exc:
            raise ValueError(f"Cannot read {ticket_path}: {exc}") from exc
        if not ticket or "\n" in ticket or "\r" in ticket:
            raise ValueError(f"{ticket_path} must contain exactly one non-empty line.")

    workspace = config.get("workspace", {})
    if not isinstance(workspace, dict):
        raise ValueError(f"workspace in {config_path} must be a TOML table.")
    configured_roots = workspace.get("roots", [])
    if not isinstance(configured_roots, list) or not all(isinstance(item, str) for item in configured_roots):
        raise ValueError(f"workspace.roots in {config_path} must be an array of strings.")

    resolved_roots = [root]
    for item in configured_roots:
        candidate = (root / item).resolve(strict=True)
        if candidate != root and root not in candidate.parents:
            raise ValueError(f"Workspace root escapes the project: {item}")
        if not candidate.is_dir():
            raise ValueError(f"Workspace root is not a directory: {item}")
        if candidate not in resolved_roots:
            resolved_roots.append(candidate)
    return {"root": root, "session": session, "ticket": ticket, "roots": resolved_roots}


def git_branch(directory):
    branch = subprocess.run(
        ["git", "-C", str(directory), "branch", "--show-current"],
        text=True, capture_output=True, check=False,
    ).stdout.strip()
    if branch:
        return branch
    commit = subprocess.run(
        ["git", "-C", str(directory), "rev-parse", "--short", "HEAD"],
        text=True, capture_output=True, check=False,
    ).stdout.strip()
    return f"detached-{commit}" if commit else None


TEMPLATE = re.compile(r"{{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*}}")


def session_label(directory):
    metadata = load_metadata(directory)
    root = metadata["root"]
    template = metadata["session"] or root.name or "project"
    values = {
        "project": root.name,
        "ticket": metadata["ticket"],
    }

    def replace(match):
        key = match.group(1)
        if key == "branch":
            value = git_branch(root)
        elif key in values:
            value = values[key]
        else:
            raise ValueError(f"Unknown session template variable: {key}")
        if not value:
            raise ValueError(f"Session template variable has no value: {key}")
        return value

    label = TEMPLATE.sub(replace, template)
    if "{{" in label or "}}" in label:
        raise ValueError(f"Invalid session template: {template}")
    if any(ord(character) < 32 for character in label):
        raise ValueError("Session label cannot contain control characters.")
    # tmux target syntax reserves dots and colons in session names.
    label = label.strip().replace(".", "_").replace(":", "_")
    if not label:
        raise ValueError("Session label cannot be empty.")
    return label


def tmux_sessions():
    result = tmux("list-sessions", "-F", "#{session_id}\t#{session_name}\t#{@project-root}", check=False)
    if result.returncode:
        return []
    sessions = []
    for line in result.stdout.splitlines():
        parts = line.split("\t", 2)
        if len(parts) == 3:
            sessions.append(tuple(parts))
    return sessions


def available_name(label, directory, sessions, current_id=None):
    suffix = hashlib.sha256(str(directory).encode()).hexdigest()[:8]
    used = {name for session_id, name, _ in sessions if session_id != current_id}
    if label == "general" or label in used:
        label = f"{label}-{suffix}"
    if label in used:
        raise ValueError(f"Session name collision: {label}")
    return label


def layout(target):
    window = tmux("display-message", "-p", "-t", target, "#{window_id}").stdout.strip()
    panes = tmux("list-panes", "-t", window, "-F", "#{pane_id}").stdout.splitlines()
    if len(panes) > 4:
        raise ValueError("Layout needs at most four panes; existing panes have been left intact.")
    cwd = tmux("display-message", "-p", "-t", target, "#{pane_current_path}").stdout.strip()
    height = int(tmux("display-message", "-p", "-t", target, "#{window_height}").stdout)
    width = int(tmux("display-message", "-p", "-t", target, "#{window_width}").stdout)
    if height < 5 or width < 8:
        raise ValueError("Window is too small for four panes.")
    main = panes[0]
    for _ in range(4 - len(panes)):
        tmux("split-window", "-d", "-h", "-t", main, "-c", cwd)
        tmux("select-layout", "-t", window, "even-horizontal")
    lower = min(12, (height - 1) // 2)
    tmux("set-window-option", "-t", window, "main-pane-height", str(height - lower - 1))
    tmux("select-layout", "-t", window, "main-horizontal")
    tmux("select-pane", "-t", main)


def start_project(target):
    """Do not launch the editor at the detached session's placeholder size."""
    previous = None
    while True:
        size = tmux("display-message", "-p", "-t", target,
                    "#{session_attached}:#{window_width}:#{window_height}").stdout.strip()
        attached, width, height = map(int, size.split(":"))
        if attached and width >= 8 and height >= 5:
            if size == previous:
                break
            previous = size
        else:
            previous = None
        time.sleep(0.05)
    # Use the same layout as the shortcut, after client sizing has settled.
    layout(target)


def ensure_project(directory):
    directory = directory.resolve(strict=True)
    if not directory.is_dir():
        raise ValueError("Project must be a directory.")
    state = Path(os.environ.get("XDG_RUNTIME_DIR", f"/tmp/tmux-projects-{os.getuid()}"))
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (state / "tmux-projects.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        sessions = tmux_sessions()
        existing = next((session for session in sessions if session[2] == str(directory)), None)
        label = session_label(directory)
        name = available_name(label, directory, sessions, existing[0] if existing else None)
        if existing:
            if existing[1] != name:
                tmux("rename-session", "-t", existing[0], name)
            return name
        pane = tmux("new-session", "-d", "-s", name, "-c", str(directory),
                    "-x", "160", "-y", "48", "-P", "-F", "#{pane_id}", "sleep infinity").stdout.strip()
        try:
            tmux("set-option", "-t", "=" + name + ":", "@project-root", str(directory))
            layout(pane)
            tmux("respawn-pane", "-k", "-t", pane, "-c", str(directory),
                 "bash", str(Path(__file__).resolve().parent.parent / "scripts" / "project-shell.sh"))
        except Exception:
            tmux("kill-session", "-t", "=" + name, check=False)
            raise
        return name


def refresh_project(directory):
    directory = directory.resolve(strict=True)
    sessions = tmux_sessions()
    existing = next((session for session in sessions if session[2] == str(directory)), None)
    if not existing:
        raise ValueError(f"No running project session for {directory}")
    name = available_name(session_label(directory), directory, sessions, existing[0])
    if existing[1] != name:
        tmux("rename-session", "-t", existing[0], name)
    return name


def process_ancestors(pid):
    """Match a tmux client to its terminal without depending on window titles."""
    ancestors = set()
    while pid > 1 and pid not in ancestors:
        ancestors.add(pid)
        try:
            pid = int(Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    return ancestors


def hyprland_command():
    """Launcher services can retain the signature of an exited compositor."""
    instances = json.loads(subprocess.check_output(["hyprctl", "instances", "-j"], text=True))
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    candidates = [instance for instance in instances if instance["instance"] == signature]
    if not candidates:
        display = os.environ.get("WAYLAND_DISPLAY")
        candidates = [instance for instance in instances if display and instance.get("wl_socket") == display]
    if not candidates and len(instances) == 1:
        candidates = instances
    if len(candidates) != 1:
        return None
    return ["hyprctl", "-i", candidates[0]["instance"]]


def workspace_terminal():
    try:
        command = hyprland_command()
        if command is None:
            return None
        def query(what):
            return json.loads(subprocess.check_output([*command, "-j", what], text=True))
        workspace = query("activeworkspace")["id"]
        windows = sorted((w for w in query("clients")
                          if w.get("mapped") and not w.get("hidden")
                          and w["workspace"]["id"] == workspace
                          and w.get("initialClass", "").lower() in ("foot", "footclient")),
                         key=lambda w: w.get("focusHistoryID", 999))
        clients = tmux("list-clients", "-F", "#{client_pid}\t#{client_tty}").stdout.splitlines()
        for window in windows:
            for client in clients:
                pid, tty = client.split("\t", 1)
                if window["pid"] in process_ancestors(int(pid)):
                    return tty, window["address"], command
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError):
        pass
    return None


def open_project(directory, graphical=True):
    name = ensure_project(directory)
    if os.environ.get("TMUX"):
        tmux("switch-client", "-t", "=" + name)
    elif not graphical:
        os.execvp("tmux", ["tmux", "attach-session", "-t", "=" + name])
    else:
        terminal = workspace_terminal()
        if terminal:
            tty, address, command = terminal
            tmux("switch-client", "-c", tty, "-t", "=" + name)
            subprocess.run([*command, "dispatch", "focuswindow", "address:" + address], check=True)
        else:
            subprocess.Popen(["foot", "tmux", "attach-session", "-t", "=" + name], start_new_session=True)


def resolve_project(selector, choices, root):
    path = Path(selector).expanduser()
    if path.is_dir():
        return path.resolve()
    matches = []
    for candidate in choices:
        if selector in (project_label(candidate, root), candidate.name):
            resolved = candidate.resolve()
            if resolved not in matches:
                matches.append(resolved)
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        raise ValueError(f"Ambiguous project '{selector}': " + ", ".join(map(str, matches)))
    raise ValueError(f"Unknown project: {selector}")


def current_project():
    if os.environ.get("TMUX_PANE"):
        root = tmux("show-options", "-qv", "-t", os.environ["TMUX_PANE"], "@project-root", check=False)
        if root.returncode == 0 and root.stdout.strip():
            return Path(root.stdout.strip()).resolve(strict=True)
    configured = find_config_root(Path.cwd())
    if (configured / ".whc").is_file():
        return configured
    result = subprocess.run(
        ["git", "-C", str(Path.cwd()), "rev-parse", "--show-toplevel"],
        text=True, capture_output=True, check=False,
    )
    return Path(result.stdout.strip()).resolve(strict=True) if result.returncode == 0 else Path.cwd().resolve()


def terminal_pick(choices, root):
    if not choices:
        raise ValueError(f"No projects found under {root}")
    entries = "".join(f"{project_label(path, root)}\t{path.resolve()}\n" for path in choices)
    selected = subprocess.run(
        ["fzf", "--delimiter=\t", "--with-nth=1", "--prompt=Projects> "],
        input=entries, text=True, capture_output=True,
    )
    if selected.returncode or not selected.stdout.strip():
        return
    open_project(Path(selected.stdout.rstrip("\n").rsplit("\t", 1)[1]), graphical=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=[
        "pick", "terminal-pick", "list", "complete", "entries", "open", "terminal-open",
        "ensure", "refresh", "roots", "layout", "start",
    ])
    parser.add_argument("target", nargs="?")
    args = parser.parse_args()
    root, infra = project_roots()
    choices = projects(root, infra)
    if args.action in ("layout", "start"):
        action = layout if args.action == "layout" else start_project
        action(args.target or os.environ.get("TMUX_PANE", ""))
    elif args.action in ("open", "terminal-open", "ensure"):
        if not args.target:
            parser.error("a project directory is required")
        if args.action == "ensure":
            print(ensure_project(Path(args.target)))
        else:
            directory = resolve_project(args.target, choices, root)
            open_project(directory, graphical=args.action == "open")
    elif args.action == "refresh":
        directory = resolve_project(args.target, choices, root) if args.target else current_project()
        print(refresh_project(directory))
    elif args.action == "roots":
        metadata = load_metadata(Path(args.target) if args.target else Path.cwd())
        print(json.dumps({
            "root": str(metadata["root"]),
            "search_dirs": [str(path) for path in metadata["roots"]],
        }))
    else:
        labels = [project_label(p, root).replace("\n", "\\n") for p in choices]
        if args.action == "entries":
            print(json.dumps([{"Text": label, "Value": str(path.resolve())}
                              for path, label in zip(choices, labels)]))
            return
        if args.action == "list":
            print("\n".join(labels))
            return
        if args.action == "complete":
            print("\n".join(dict.fromkeys([*labels, *(path.name for path in choices)])))
            return
        if args.action == "terminal-pick":
            terminal_pick(choices, root)
            return
        if not choices:
            raise ValueError(f"No projects found under {root}")
        selected = subprocess.run(["walker", "--dmenu", "--index", "--placeholder", "Projects"],
                                  input="\n".join(labels) + "\n", text=True, capture_output=True)
        if selected.returncode or not selected.stdout.strip():
            return
        index = int(selected.stdout.strip())
        if not 0 <= index < len(choices):
            raise ValueError("Invalid project selection")
        open_project(choices[index])


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        message = exc.stderr.strip() if isinstance(exc, subprocess.CalledProcessError) else str(exc)
        print(message, file=sys.stderr)
        if os.environ.get("TMUX"):
            tmux("display-message", message, check=False)
        elif shutil.which("notify-send"):
            subprocess.run(["notify-send", "Projects", message], check=False)
        sys.exit(1)
