"""Tests for whc-theme: every theme x variant x target renders, managed blocks are idempotent,
and `apply` into a scratch dotfiles tree is repeatable.

Run:  python3 -B -m unittest discover -s tests -p 'test_*.py'   (or `just test`)
Also runs from a vendored copy where this file sits next to the whc-theme script.
"""
import contextlib
import importlib.machinery
import io
import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / "whc-theme" if (HERE / "whc-theme").is_file() else HERE.parent / "whc-theme"
_loader = importlib.machinery.SourceFileLoader("whc_theme", str(SCRIPT))
_spec = importlib.util.spec_from_loader("whc_theme", _loader)
W = importlib.util.module_from_spec(_spec)
sys.modules["whc_theme"] = W  # dataclasses look their module up here
_loader.exec_module(W)


class RenderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.themes = W.load_themes()

    def test_expected_themes(self):
        for tid in ["meadow-night", "meadow-day", "dracula-meadow", "dracula", "dracula-pro", "dracula-pro-blade",
                    "dracula-pro-buffy", "dracula-pro-lincoln", "dracula-pro-morbius", "dracula-pro-van-helsing",
                    "dracula-pro-alucard"]:
            self.assertIn(tid, self.themes)

    def test_every_target_renders(self):
        root, home = Path("/nonexistent/dotfiles"), Path("/nonexistent/home")
        for t in self.themes.values():
            for variant in ("auto", "base", "cowgirl", "ranch"):
                ctx = W.Ctx(t, variant, root, home)
                for target in W.TARGETS.values():
                    outs = target.render(ctx)
                    self.assertTrue(outs, f"{target.name} rendered nothing")
                    for o in outs:
                        self.assertTrue(o.content.strip(), f"{target.name}/{t['id']}/{variant} empty")
                        self.assertNotIn("None", o.content.replace("Nonexistent", ""),
                                         f"{target.name}/{t['id']}/{variant} leaked a None")

    def test_json_targets_parse(self):
        t = self.themes["meadow-night"]
        ctx = W.Ctx(t, "auto", Path("/x"), Path("/y"))
        for name in ("windows-terminal", "firefox-manifest"):
            json.loads(W.TARGETS[name].render(ctx)[0].content)

    def test_konsole_is_ini(self):
        import configparser
        ctx = W.Ctx(self.themes["meadow-night"], "cowgirl", Path("/x"), Path("/y"))
        text = W.TARGETS["konsole"].render(ctx)[0].content
        cp = configparser.ConfigParser()
        cp.read_string("\n".join(line for line in text.splitlines() if not line.startswith("#")))
        self.assertEqual(cp["Background"]["Color"], "40,26,23")
        for i in range(8):
            for suffix in ("", "Intense", "Faint"):
                self.assertIn(f"Color{i}{suffix}", cp)

    def test_slack_string(self):
        ctx = W.Ctx(self.themes["meadow-night"], "cowgirl", Path("/x"), Path("/y"))
        vals = W.TARGETS["slack"].render(ctx)[0].content.strip().split(",")
        self.assertEqual(len(vals), 10)

    def test_block_splice_is_idempotent(self):
        base = "[main]\nfont=x\n\n[urgency=critical]\ndefault-timeout=0\n"
        once = W.splice_block(base, "a=1\n", before_first_section=True)
        twice = W.splice_block(once, "a=1\n", before_first_section=True)
        self.assertEqual(once, twice)
        changed = W.splice_block(once, "a=2\n", before_first_section=True)
        self.assertIn("a=2", changed)
        self.assertNotIn("a=1", changed)


class HelperTests(unittest.TestCase):
    def test_ini_set_keeps_other_keys(self):
        text = "[General]\nName=Old\nParent=FALLBACK/\n\n[Appearance]\nFont=Hack,11\n"
        out = W.ini_set(text, "Appearance", "ColorScheme", "WHC")
        out = W.ini_set(out, "General", "Name", "WHC")
        self.assertIn("Font=Hack,11", out)
        self.assertEqual(W.ini_get(out, "Appearance", "ColorScheme"), "WHC")
        self.assertEqual(W.ini_get(out, "General", "Name"), "WHC")
        self.assertEqual(W.ini_get(out, "General", "Parent"), "FALLBACK/")
        self.assertEqual(W.ini_set(out, "General", "Name", "WHC"), out)
        self.assertEqual(W.ini_get(W.ini_set("", "Desktop Entry", "DefaultProfile", "WHC.profile"),
                                   "Desktop Entry", "DefaultProfile"), "WHC.profile")

    def test_adw_accent(self):
        self.assertEqual(W.adw_accent("#E89CB5"), "pink")
        self.assertEqual(W.adw_accent("#3584E4"), "blue")
        self.assertEqual(W.adw_accent("#808080"), "slate")

    def test_css_block_markers(self):
        once = W.splice_block("a { }\n", "b { }\n", comment="/*", close=" */")
        self.assertIn("/* >>> whc-theme >>> */", once)
        self.assertEqual(once, W.splice_block(once, "b { }\n", comment="/*", close=" */"))


class ApplyTests(unittest.TestCase):
    def test_apply_twice_changes_nothing(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for rel in ("shell/.tmux.conf", "foot/foot.ini", "mako/config", "termux/colors.properties",
                        "hypr/hyprland.lua"):
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text("font=x\n\n[urgency=critical]\ndefault-timeout=0\n" if "mako" in rel else "x=1\n")
            env = dict(os.environ, WHC_THEME_STATE=str(root / "state.toml"))
            old = os.environ.copy()
            os.environ.update(env)
            try:
                themes = W.load_themes()
                args = type("A", (), {"theme": "meadow-night", "variant": "auto", "root": str(root), "targets": None,
                                      "dry_run": False, "home": None})
                with contextlib.redirect_stdout(io.StringIO()):
                    W.cmd_apply(args, themes)
                first = {p: p.read_text() for p in root.rglob("*") if p.is_file()}
                with contextlib.redirect_stdout(io.StringIO()):
                    W.cmd_apply(args, themes)
                second = {p: p.read_text() for p in root.rglob("*") if p.is_file() and p.name != "state.toml"}
                for p, text in second.items():
                    self.assertEqual(first[p], text, p)
                self.assertTrue((root / "shell/.tmux.theme.conf").exists())
                self.assertIn('theme = "meadow-night"', (root / "whc-theme/theme.toml").read_text())
            finally:
                os.environ.clear()
                os.environ.update(old)


    def _apply_local(self, home, targets, variant="felicia"):
        old = os.environ.copy()
        os.environ["WHC_THEME_STATE"] = str(home / "state.toml")
        os.environ.pop("WHC_FIREFOX_PROFILE", None)
        try:
            args = type("A", (), {"theme": "meadow-night", "variant": variant, "root": str(home / "nodots"),
                                  "targets": targets, "dry_run": False, "home": str(home)})
            with contextlib.redirect_stdout(io.StringIO()):
                W.cmd_apply(args, W.load_themes())
        finally:
            os.environ.clear()
            os.environ.update(old)

    def test_konsole_profile_and_default(self):
        with tempfile.TemporaryDirectory() as d:
            home = Path(d)
            data = home / ".local/share/konsole"
            data.mkdir(parents=True)
            (data / "Mine.profile").write_text("[Appearance]\nColorScheme=Breeze\nFont=Hack,12\n\n[General]\nName=Mine\n")
            (home / ".config").mkdir()
            (home / ".config/konsolerc").write_text("[Desktop Entry]\nDefaultProfile=Mine.profile\n\n[MainWindow]\nX=1\n")
            self._apply_local(home, "konsole")
            prof = (data / "WHC.profile").read_text()
            self.assertIn("Font=Hack,12", prof)
            self.assertEqual(W.ini_get(prof, "Appearance", "ColorScheme"), "WHC")
            rc = (home / ".config/konsolerc").read_text()
            self.assertEqual(W.ini_get(rc, "Desktop Entry", "DefaultProfile"), "WHC.profile")
            self.assertIn("X=1", rc)
            self.assertIn("DefaultProfile=Mine.profile", (home / ".config/konsolerc.whc-backup").read_text())
            self.assertIn("felicia", (data / "WHC.colorscheme").read_text())
            self.assertIn("ColorScheme=Breeze", (data / "Mine.profile").read_text())
            before = {p: p.read_text() for p in home.rglob("*") if p.is_file() and p.name != "state.toml"}
            self._apply_local(home, "konsole")
            after = {p: p.read_text() for p in home.rglob("*") if p.is_file() and p.name != "state.toml"}
            self.assertEqual(before, after)

    def test_firefox_profile(self):
        with tempfile.TemporaryDirectory() as d:
            home = Path(d)
            root = home / ".config/mozilla/firefox"
            prof = root / "abc.default-release"
            prof.mkdir(parents=True)
            (prof / "prefs.js").write_text("")
            (root / "unused.default").mkdir()
            (root / "profiles.ini").write_text("[Profile0]\nName=default-release\nIsRelative=1\nPath=abc.default-release\n\n"
                                               "[Profile1]\nName=default\nIsRelative=1\nPath=unused.default\n")
            (prof / "user.js").write_text('user_pref("a", 1);\n')
            self.assertEqual(W.firefox_profiles(home), [prof])
            self._apply_local(home, "firefox", variant="cowgirl")
            css = (prof / "chrome/userChrome.css").read_text()
            self.assertIn("--lwt-accent-color: #281A17 !important;", css)
            self.assertIn("--lwt-tab-line-color: #D78F84 !important;", css)
            js = (prof / "user.js").read_text()
            self.assertIn('user_pref("a", 1);', js)
            self.assertIn("legacyUserProfileCustomizations.stylesheets\", true", js)
            self.assertTrue((prof / "user.js.whc-backup").exists())
            self.assertFalse((root / "unused.default/chrome").exists())

    def test_machine_group_uses_detection(self):
        ctx = W.Ctx(W.load_themes()["meadow-night"], "auto", Path("/x"), Path("/nonexistent"))
        names = [t.name for t in W.selected_targets("machine", ctx)]
        self.assertNotIn("firefox", names)
        self.assertNotIn("tmux", names)
        self.assertEqual([t.name for t in W.selected_targets("tmux,tmux", ctx)], ["tmux"])


if __name__ == "__main__":
    unittest.main()
