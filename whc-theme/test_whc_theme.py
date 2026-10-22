"""Tests for whc-theme: every theme x variant x target renders, managed blocks are idempotent,
and `apply` into a scratch dotfiles tree is repeatable.

Run:  python3 -B -m unittest discover -s <dir containing whc-theme> -p 'test_*.py'
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
_loader = importlib.machinery.SourceFileLoader("whc_theme", str(HERE / "whc-theme"))
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
        for name in ("windows-terminal", "firefox"):
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


class ApplyTests(unittest.TestCase):
    def test_apply_twice_changes_nothing(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for rel in ("shell/.tmux.conf", "foot/foot.ini", "mako/config", "termux/colors.properties"):
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text("font=x\n\n[urgency=critical]\ndefault-timeout=0\n" if "mako" in rel else "x=1\n")
            env = dict(os.environ, WHC_THEME_STATE=str(root / "state.toml"))
            old = os.environ.copy()
            os.environ.update(env)
            try:
                themes = W.load_themes()
                args = type("A", (), {"theme": "meadow-night", "variant": "auto", "root": str(root), "targets": None,
                                      "dry_run": False})
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


if __name__ == "__main__":
    unittest.main()
