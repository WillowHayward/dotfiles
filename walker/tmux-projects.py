#!/usr/bin/env python3
"""Walker project picker and explicit tmux workspace layout."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def tmux(*args, check=True):
    return subprocess.run(["tmux", *args], text=True, capture_output=True, check=check)


def projects(root):
    entries = [p for p in root.iterdir() if p.is_dir() and not p.name.startswith(".")] if root.is_dir() else []
    infra = root / "infra"
    if infra.is_dir():
        entries += [p for p in infra.iterdir() if p.is_dir() and not p.name.startswith(".")]
    dotfiles = Path.home() / "dotfiles"
    if dotfiles.is_dir() and dotfiles.resolve() not in {p.resolve() for p in entries}:
        entries.append(dotfiles)
    return sorted(entries, key=lambda p: (p.resolve() != dotfiles.resolve(),
                                          project_label(p, root).casefold()))


def project_label(directory, root):
    if directory.resolve() == (Path.home() / "dotfiles").resolve():
        return "dotfiles"
    if directory.is_relative_to(root):
        return str(directory.relative_to(root))
    if directory.is_relative_to(Path.home()):
        return "~/" + str(directory.relative_to(Path.home()))
    return str(directory)


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
        # tmux reserves dots and colons in session names.
        base = directory.name.replace(".", "_").replace(":", "_") or "project"
        suffix = hashlib.sha256(str(directory).encode()).hexdigest()[:8]
        if base == "general":
            base = f"{base}-{suffix}"
        name = base
        while tmux("has-session", "-t", "=" + name, check=False).returncode == 0:
            root = tmux("show-options", "-qv", "-t", "=" + name + ":", "@project-root").stdout.strip()
            if root == str(directory):
                return name
            if name != base:
                raise ValueError(f"Session name collision: {name}")
            name = f"{base}-{suffix}"
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


def open_project(directory):
    name = ensure_project(directory)
    if os.environ.get("TMUX"):
        tmux("switch-client", "-t", "=" + name)
    else:
        terminal = workspace_terminal()
        if terminal:
            tty, address, command = terminal
            tmux("switch-client", "-c", tty, "-t", "=" + name)
            subprocess.run([*command, "dispatch", "focuswindow", "address:" + address], check=True)
        else:
            subprocess.Popen(["foot", "tmux", "attach-session", "-t", "=" + name], start_new_session=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["pick", "list", "entries", "open", "ensure", "layout", "start"])
    parser.add_argument("target", nargs="?")
    args = parser.parse_args()
    root = Path(os.environ.get("WHC_PROJECTS_DIR", str(Path.home() / "projects"))).expanduser()
    if args.action in ("layout", "start"):
        action = layout if args.action == "layout" else start_project
        action(args.target or os.environ.get("TMUX_PANE", ""))
    elif args.action in ("open", "ensure"):
        if not args.target:
            parser.error("a project directory is required")
        if args.action == "ensure":
            print(ensure_project(Path(args.target)))
        else:
            open_project(Path(args.target))
    else:
        choices = projects(root)
        labels = [project_label(p, root).replace("\n", "\\n") for p in choices]
        if args.action == "entries":
            print(json.dumps([{"Text": label, "Value": str(path.resolve())}
                              for path, label in zip(choices, labels)]))
            return
        if args.action == "list":
            print("\n".join(labels))
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
        else:
            subprocess.run(["notify-send", "Projects", message], check=False)
        sys.exit(1)
