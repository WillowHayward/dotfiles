#!/usr/bin/env python3
"""tmux status-bar segments: AI usage and battery.

Usage: scripts/status-line.py [ai|battery]   (no argument prints both)

AI usage depends on the profile (WHC_PROFILE):
  home  Codex and Claude: remaining 5-hour / remaining weekly percentages.
        Codex comes from the rate limits its own session logs record (~/.codex/sessions).
        Claude's usage comes from Anthropic's OAuth usage endpoint, called with the access token that
        Claude Code stores in ~/.claude/.credentials.json (read-only, sent only to api.anthropic.com,
        never printed or cached). WHC_CLAUDE_USAGE_CMD, if set, replaces that with your own command
        printing e.g. "72%/85%".
  work  Copilot: remaining AI credits and the percentage used, from `gh api /copilot_internal/user`.
Results are cached under ~/.cache/whc/status/ so the status bar stays cheap; failures print a dash
instead of an error. Icons are Nerd Font glyphs; override with WHC_ICON_CODEX, WHC_ICON_CLAUDE,
WHC_ICON_COPILOT. Output uses tmux style codes (#[fg=...]).
"""
import glob
import json
import os
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "whc" / "status"
COLORS = {"dim": "#6272A4", "text": "#F8F8F2", "green": "#50FA7B", "yellow": "#F1FA8C", "orange": "#FFB86C", "red": "#FF5555", "purple": "#BD93F9"}
ICONS = {
    "codex": os.environ.get("WHC_ICON_CODEX", "\uec81"),  # Codex
    "claude": os.environ.get("WHC_ICON_CLAUDE", "\uec82"),  # Claude
    "copilot": os.environ.get("WHC_ICON_COPILOT", "\uf4b8"),  # Octicons copilot
}


def colour(name, text):
    return f"#[fg={COLORS[name]}]{text}#[default]"


def level_colour(remaining):
    return "red" if remaining < 15 else "orange" if remaining < 40 else "green"


def cached(name, ttl, produce):
    """Return produce()'s text, reusing a cache file younger than ttl seconds."""
    path = CACHE / name
    try:
        if time.time() - path.stat().st_mtime < ttl:
            return path.read_text()
    except OSError:
        pass
    try:
        value = produce()
    except Exception:  # A status bar must never raise.
        value = None
    if value is None:
        try:
            return path.read_text()  # Stale beats blank.
        except OSError:
            return ""
    CACHE.mkdir(parents=True, exist_ok=True)
    path.write_text(value)
    return value


def profile():
    name = os.environ.get("WHC_PROFILE")
    if name:
        return name
    try:
        for line in Path("/etc/environment").read_text().splitlines():
            if line.startswith("WHC_PROFILE="):
                name = line.split("=", 1)[1].strip().strip('"')
    except OSError:
        pass
    return name or "home"


def codex_rate_limits():
    """Newest rate_limits entry in Codex's session logs, or None."""
    files = sorted(glob.glob(str(Path.home() / ".codex/sessions/**/*.jsonl"), recursive=True), key=os.path.getmtime, reverse=True)
    for path in files[:5]:
        with open(path, "rb") as handle:
            handle.seek(0, os.SEEK_END)
            handle.seek(max(0, handle.tell() - 400_000))
            lines = handle.read().decode("utf-8", "ignore").splitlines()
        for line in reversed(lines):
            if '"rate_limits"' not in line:
                continue
            try:
                event = json.loads(line)
            except ValueError:
                continue
            payload = event.get("payload", event)
            limits = payload.get("rate_limits") or payload.get("info", {}).get("rate_limits")
            if limits and limits.get("primary"):
                return limits
    return None


def remaining(window):
    """Percent left in a rate-limit window; a window that has reset is full again."""
    if not window:
        return None
    if window.get("resets_at") and window["resets_at"] < time.time():
        return 100.0
    return max(0.0, 100.0 - float(window.get("used_percent", 0)))


def pair(five_hour, weekly):
    if five_hour is None or weekly is None:
        return colour("dim", "-/-")
    return f"{colour(level_colour(five_hour), f'{five_hour:.0f}%')}{colour('dim', '/')}{colour(level_colour(weekly), f'{weekly:.0f}%')}"


def codex_segment():
    def produce():
        limits = codex_rate_limits()
        if not limits:
            return None
        return json.dumps([remaining(limits.get("primary")), remaining(limits.get("secondary"))])

    try:
        five_hour, weekly = json.loads(cached("codex.json", 60, produce) or "[null, null]")
    except ValueError:
        five_hour = weekly = None
    return f"{colour('purple', ICONS['codex'])} {pair(five_hour, weekly)}"


def claude_usage():
    """Remaining 5-hour and weekly percentages from the OAuth usage endpoint, as JSON text."""
    credentials = json.loads(Path.home().joinpath(".claude/.credentials.json").read_text())
    token = credentials["claudeAiOauth"]["accessToken"]
    request = urllib.request.Request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={"Authorization": f"Bearer {token}", "anthropic-beta": "oauth-2025-04-20", "User-Agent": "whc-status-line"},
    )
    with urllib.request.urlopen(request, timeout=8) as response:
        usage = json.load(response)

    def left(window):
        used = (usage.get(window) or {}).get("utilization")
        return None if used is None else max(0.0, 100.0 - float(used))

    return json.dumps([left("five_hour"), left("seven_day")])


def claude_segment():
    command = os.environ.get("WHC_CLAUDE_USAGE_CMD")
    icon = colour("orange", ICONS["claude"])
    if command:
        def produce():
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=10, check=True)
            return result.stdout.strip()

        return f"{icon} {cached('claude.txt', 120, produce).strip() or colour('dim', '-/-')}"
    try:
        five_hour, weekly = json.loads(cached("claude.json", 120, claude_usage) or "[null, null]")
    except ValueError:
        five_hour = weekly = None
    return f"{icon} {pair(five_hour, weekly)}"


def copilot_segment():
    def produce():
        result = subprocess.run(["gh", "api", "/copilot_internal/user"], capture_output=True, text=True, timeout=10, check=True)
        snapshots = json.loads(result.stdout).get("quota_snapshots", {})
        quota = snapshots.get("premium_interactions") or {}
        if not quota.get("entitlement"):
            quota = snapshots.get("chat") or {}
        return json.dumps([quota.get("remaining"), quota.get("percent_remaining")])

    try:
        credits, percent_left = json.loads(cached("copilot.json", 300, produce) or "[null, null]")
    except ValueError:
        credits = percent_left = None
    if credits is None or percent_left is None:
        return f"{colour('purple', ICONS['copilot'])} {colour('dim', '-')}"
    used = 100 - float(percent_left)
    return f"{colour('purple', ICONS['copilot'])} {colour(level_colour(float(percent_left)), f'{credits:.0f} AIC')} {colour('dim', f'({used:.0f}% used)')}"


def battery_segment():
    for supply in sorted(glob.glob("/sys/class/power_supply/BAT*")):
        try:
            capacity = int(Path(supply, "capacity").read_text())
            status = Path(supply, "status").read_text().strip()
        except (OSError, ValueError):
            continue
        glyphs = ""  # empty .. full
        glyph = "" if status == "Charging" else glyphs[min(4, capacity // 20)]
        return f"{colour(level_colour(capacity) if status != 'Charging' else 'green', f'{glyph} {capacity}%')}"
    return ""


def ai_segment():
    segments = {"home": [codex_segment, claude_segment], "work": [copilot_segment]}.get(profile(), [])
    return "  ".join(segment() for segment in segments)


if __name__ == "__main__":
    wanted = sys.argv[1:] or ["ai", "battery"]
    parts = {"ai": ai_segment, "battery": battery_segment}
    unknown = [name for name in wanted if name not in parts]
    if unknown:
        sys.exit(f"Unknown segment(s): {', '.join(unknown)}. Choose from: ai, battery.")
    print("  ".join(text for text in (parts[name]() for name in wanted) if text))
