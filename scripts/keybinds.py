#!/usr/bin/env python3
"""Print the live keybinds as Markdown tables: hypr, tmux and nvim (default: all three).

Usage: scripts/keybinds.py [hypr|tmux|nvim ...]
Hyprland binds come from `hyprctl binds -j`, so descriptions are the ones set in
hypr/*.lua and Hyprland has to be running. tmux lists only binds that differ from tmux's
defaults. Neovim lists normal-mode mappings that have a description (needs `nvim`).
"""
import json
import re
import subprocess
import sys
import tempfile
import textwrap

MODS = ((64, "Super"), (4, "Ctrl"), (8, "Alt"), (1, "Shift"))


def run(*command, check=True):
    return subprocess.run(command, text=True, capture_output=True, check=check).stdout


def table(title, headers, rows):
    out = [f"## {title}", "", "| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for row in rows:
        out.append("| " + " | ".join(str(cell).replace("|", "\\|") for cell in row) + " |")
    return "\n".join(out) + "\n"


def hypr():
    try:
        binds = json.loads(run("hyprctl", "binds", "-j"))
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return "## Hyprland\n\nHyprland is not running here (hyprctl binds failed).\n"
    rows = []
    for bind in binds:
        mods = "+".join(name for bit, name in MODS if bind["modmask"] & bit)
        key = f"{mods}+{bind['key']}" if mods else bind["key"]
        rows.append((key, bind["description"] or "(no description)"))
    return table("Hyprland", ("Keys", "Action"), sorted(rows))


def tmux():
    try:
        mine = run("tmux", "list-keys")
        defaults = run("tmux", "-L", "whc-keys-defaults", "-f", "/dev/null", "start-server", ";", "list-keys", check=False)
    except OSError:
        return "## tmux\n\ntmux is not installed.\n"
    finally:
        subprocess.run(["tmux", "-L", "whc-keys-defaults", "kill-server"], capture_output=True, check=False)
    known = set(defaults.splitlines())
    rows = []
    for line in mine.splitlines():
        if line in known or not line.strip():
            continue
        match = re.match(r"bind-key\s+(?:-r\s+)?-T\s+(\S+)\s+(\S+)\s+(.*)$", line)
        rows.append(match.groups() if match else ("", "", line))
    return table("tmux (differs from the defaults; prefix is Ctrl+Space)", ("Table", "Key", "Command"), sorted(rows))


NVIM_LUA = textwrap.dedent("""
    local rows = {}
    for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
        if map.desc and map.desc ~= "" and not map.desc:find("^:help") then
            rows[#rows + 1] = { map.lhs:gsub(" ", "<Space>"), map.desc }
        end
    end
    io.stdout:write(vim.json.encode(rows))
""")


def nvim():
    with tempfile.NamedTemporaryFile("w", suffix=".lua") as script:
        script.write(NVIM_LUA)
        script.flush()
        try:
            output = run("nvim", "--headless", "-c", f"luafile {script.name}", "-c", "qa!", check=False)
        except OSError:
            return "## Neovim\n\nnvim is not installed.\n"
    start = output.find("[[")
    if start < 0:
        return "## Neovim\n\nNo described mappings found.\n"
    rows = json.loads(output[start:output.rfind("]") + 1])
    return table("Neovim (normal mode, <Space> is the leader)", ("Keys", "Action"), sorted(rows))


SECTIONS = {"hypr": hypr, "tmux": tmux, "nvim": nvim}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(SECTIONS)
    unknown = [name for name in wanted if name not in SECTIONS]
    if unknown:
        sys.exit(f"Unknown section(s): {', '.join(unknown)}. Choose from: {', '.join(SECTIONS)}.")
    print("# Keybinds\n")
    print("\n".join(SECTIONS[name]() for name in wanted))
