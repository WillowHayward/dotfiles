import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch, Mock


spec = importlib.util.spec_from_file_location("tmux_projects", Path(__file__).with_name("tmux-projects.py"))
projects = importlib.util.module_from_spec(spec)
spec.loader.exec_module(projects)


class MetadataTests(unittest.TestCase):
    def test_ticket_file_overrides_config_and_workspace_roots_are_resolved(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "nested" / "src").mkdir(parents=True)
            (root / ".whc").write_text(
                'session = "{{ project }} - {{ ticket }} - {{ branch }}"\n'
                'ticket = "CONFIG-1"\n\n[workspace]\nroots = ["nested", "nested"]\n'
            )
            (root / ".ticket").write_text("FILE-2\n")
            with patch.object(projects, "git_branch", return_value="feature/test"):
                self.assertEqual(projects.session_label(root / "nested" / "src"),
                                 f"{root.name} - FILE-2 - feature/test")
            metadata = projects.load_metadata(root / "nested")
            self.assertEqual(metadata["root"], root)
            self.assertEqual(metadata["roots"], [root, root / "nested"])

    def test_missing_template_value_is_an_error(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / ".whc").write_text('session = "Work - {{ ticket }}"\n')
            with patch.object(projects, "git_branch", return_value="main"):
                with self.assertRaisesRegex(ValueError, "ticket"):
                    projects.session_label(root)

    def test_detached_head_uses_short_commit(self):
        replies = [Mock(stdout=""), Mock(stdout="abc1234\n")]
        with patch.object(projects.subprocess, "run", side_effect=replies):
            self.assertEqual(projects.git_branch(Path("/project")), "detached-abc1234")

    def test_multiline_ticket_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / ".ticket").write_text("ONE\nTWO\n")
            with self.assertRaisesRegex(ValueError, "exactly one"):
                projects.load_metadata(root)

    def test_workspace_root_cannot_escape_project(self):
        with tempfile.TemporaryDirectory() as temporary:
            parent = Path(temporary)
            root = parent / "project"
            root.mkdir()
            (root / ".whc").write_text('[workspace]\nroots = [".."]\n')
            with self.assertRaisesRegex(ValueError, "escapes"):
                projects.load_metadata(root)

    def test_explicit_ignored_repo_keeps_its_own_ignore_rules(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            nested = root / "nested"
            (nested / ".git").mkdir(parents=True)
            (root / ".gitignore").write_text("/nested/\n")
            (nested / ".gitignore").write_text("ignored.txt\n")
            (nested / "visible.txt").write_text("visible\n")
            (nested / "ignored.txt").write_text("ignored\n")
            result = subprocess.run(
                ["rg", "--files", "--hidden", "--glob", "!**/.git/*", str(root), str(nested)],
                cwd=root, text=True, capture_output=True, check=True,
            ).stdout.splitlines()
            self.assertIn(str(nested / "visible.txt"), result)
            self.assertNotIn(str(nested / "ignored.txt"), result)
            self.assertFalse(any("/.git/" in line for line in result))


class SessionMetadataTests(unittest.TestCase):
    def test_existing_project_session_is_renamed_by_stable_id(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            sessions = [("$1", "old-name", str(root))]
            with patch.object(projects, "tmux_sessions", return_value=sessions), \
                    patch.object(projects, "session_label", return_value="Foo - TK-1234"), \
                    patch.object(projects, "tmux") as tmux, \
                    patch.dict(os.environ, {"XDG_RUNTIME_DIR": temporary}):
                self.assertEqual(projects.ensure_project(root), "Foo - TK-1234")
            tmux.assert_called_once_with("rename-session", "-t", "$1", "Foo - TK-1234")

    def test_name_collision_gets_path_suffix(self):
        directory = Path("/tmp/example")
        name = projects.available_name("Foo", directory, [("$1", "Foo", "/other")])
        self.assertRegex(name, r"^Foo-[0-9a-f]{8}$")


class ProjectResolutionTests(unittest.TestCase):
    def test_unique_basename_resolves(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            project = root / "group" / "app"
            project.mkdir(parents=True)
            self.assertEqual(projects.resolve_project("app", [project], root), project.resolve())

    def test_duplicate_basename_is_ambiguous(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            choices = [root / "one" / "app", root / "two" / "app"]
            for choice in choices:
                choice.mkdir(parents=True)
            with self.assertRaisesRegex(ValueError, "Ambiguous"):
                projects.resolve_project("app", choices, root)


class PrototypeTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.base = Path(temp.name).resolve()
        for name in ("projects/app", "projects/shared", "prototypes/idea", "prototypes/shared", "dotfiles"):
            (self.base / name).mkdir(parents=True)
        env = patch.dict(os.environ, {"WHC_DOTFILES_DIR": str(self.base / "dotfiles"),
                                      "WHC_PROTO_DIR": str(self.base / "prototypes")})
        env.start()
        self.addCleanup(env.stop)
        self.root = self.base / "projects"

    def labels(self):
        return [projects.project_label(p, self.root)
                for p in projects.projects(self.root, self.base / "infra")]

    def test_prototypes_are_listed_last_with_a_prefix(self):
        self.assertEqual(self.labels(), ["dotfiles", "app", "shared", "proto/idea", "proto/shared"])

    def test_project_wins_a_shared_name_and_the_prefix_selects_the_prototype(self):
        choices = projects.projects(self.root, self.base / "infra")
        self.assertEqual(projects.resolve_project("shared", choices, self.root), self.root / "shared")
        self.assertEqual(projects.resolve_project("proto/shared", choices, self.root),
                         self.base / "prototypes" / "shared")
        self.assertEqual(projects.resolve_project("idea", choices, self.root), self.base / "prototypes" / "idea")

    def test_new_creates_nested_directories_and_a_repository(self):
        directory = projects.create_project("group/tool", self.root)
        self.assertEqual(directory, self.root / "group" / "tool")
        self.assertTrue((directory / ".git").is_dir())
        prototype = projects.create_project("sketch", self.root, prototype=True)
        self.assertEqual(prototype, self.base / "prototypes" / "sketch")

    def test_local_roots_share_the_plain_namespace(self):
        for name in ("local/undocked", "local-proto/sketch"):
            (self.base / name).mkdir(parents=True)
        with patch.dict(os.environ, {"WHC_LOCAL_PROJECTS_DIR": str(self.base / "local"),
                                     "WHC_LOCAL_PROTO_DIR": str(self.base / "local-proto")}):
            self.assertEqual(self.labels(), ["dotfiles", "app", "shared", "undocked",
                                             "proto/idea", "proto/shared", "proto/sketch"])
            choices = projects.projects(self.root, self.base / "infra")
            self.assertEqual(projects.resolve_project("undocked", choices, self.root),
                             self.base / "local" / "undocked")
            self.assertEqual(projects.resolve_project("proto/sketch", choices, self.root),
                             self.base / "local-proto" / "sketch")
            local = projects.create_project("away", self.root, local=True)
            self.assertEqual(local, self.base / "local" / "away")
            # One place per project: a name taken in either root is refused.
            with self.assertRaisesRegex(ValueError, "Already exists"):
                projects.create_project("undocked", self.root)
            with self.assertRaisesRegex(ValueError, "Already exists"):
                projects.create_project("app", self.root, local=True)

    def test_new_refuses_an_unmounted_root(self):
        with self.assertRaisesRegex(ValueError, "mounted"):
            projects.create_project("tool", self.base / "unplugged")
        with self.assertRaisesRegex(ValueError, "not set"):
            projects.create_project("tool", self.root, local=True)

    def test_new_refuses_existing_and_escaping_names(self):
        for name in ("app", "../outside", "/abs", "a/../b", ".hidden", ""):
            with self.subTest(name=name), self.assertRaises(ValueError):
                projects.create_project(name, self.root)


class PickerListTests(unittest.TestCase):
    def layout(self, infra_whc=None):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        base = Path(temp.name).resolve()
        for name in ("projects/alpha", "projects/beta", "infra/ship", "infra/bessie", "infra/notes", "dotfiles"):
            (base / name).mkdir(parents=True)
        (base / "projects/.hidden").mkdir()
        if infra_whc is not None:
            (base / "infra/.whc").write_text(infra_whc)
        env = {"WHC_DOTFILES_DIR": str(base / "dotfiles"), "WHC_PROTO_DIR": str(base / "prototypes")}
        return base, env

    def names(self, base, env):
        with patch.dict(os.environ, env, clear=False):
            return [path.name for path in projects.projects(base / "projects", base / "infra")]

    def test_infra_is_one_option_without_a_whc_file(self):
        base, env = self.layout()
        self.assertEqual(set(self.names(base, env)), {"dotfiles", "alpha", "beta", "infra"})

    def test_infra_workspace_roots_are_listed_once_it_has_a_whc_file(self):
        base, env = self.layout('[workspace]\nroots = ["ship", "bessie"]\n')
        names = self.names(base, env)
        self.assertEqual(set(names), {"dotfiles", "alpha", "beta", "bessie", "infra", "ship"})
        self.assertEqual(names[0], "dotfiles")
        self.assertNotIn("notes", names)

    def test_broken_infra_whc_does_not_empty_the_picker(self):
        base, env = self.layout("not = [valid")
        self.assertEqual(set(self.names(base, env)), {"dotfiles", "alpha", "beta", "infra"})


class DirectoryMetadataTests(unittest.TestCase):
    """The .whc/ directory (project.yml, workspace.yml, local/ticket), with the legacy file as fallback."""

    def make(self, files):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name).resolve()
        for name, content in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        return root

    def test_project_yml_workspace_yml_and_local_ticket(self):
        root = self.make({
            ".whc/project.yml": 'name: Farmhand\ncode: FH\nlabels: [homelab, rust]\nsession: "{{ project }} - {{ ticket }}"\n',
            ".whc/workspace.yml": "repos:\n  core:    {path: core,    url: git@github.com:o/Farmhand.git}\n"
                                  "  premium: {path: premium, url: git@github.com:o/Farmhand-premium.git}\n"
                                  "roots: [core, premium]\n",
            ".whc/local/ticket": "FH-12\n",
            ".ticket": "OLD-1\n",
            "core/src/x": "", "premium/x": "",
        })
        metadata = projects.load_metadata(root / "core" / "src")
        self.assertEqual((metadata["root"], metadata["name"], metadata["code"], metadata["labels"]),
                         (root, "Farmhand", "FH", ["homelab", "rust"]))
        self.assertEqual(metadata["roots"], [root, root / "core", root / "premium"])
        self.assertEqual(metadata["ticket"], "FH-12")  # local/ticket replaces .ticket
        self.assertEqual(projects.session_label(root), f"{root.name} - FH-12")

    def test_root_can_be_a_path_not_in_repos(self):
        root = self.make({".whc/workspace.yml": "roots: [tools]\n", "tools/x": ""})
        self.assertEqual(projects.load_metadata(root)["roots"], [root, root / "tools"])

    def test_legacy_ticket_file_still_works_beside_a_directory(self):
        root = self.make({".whc/project.yml": 'name: A\ncode: AA\nsession: "S - {{ ticket }}"\n', ".ticket": "OLD-1\n"})
        self.assertEqual(projects.session_label(root), "S - OLD-1")

    def test_workspace_root_cannot_escape_project_in_workspace_yml(self):
        root = self.make({".whc/workspace.yml": "roots: [..]\n"})
        with self.assertRaisesRegex(ValueError, "escapes"):
            projects.load_metadata(root)

    def test_legacy_toml_file_is_the_fallback(self):
        root = self.make({".whc": 'session = "Old - {{ project }}"\n[workspace]\nroots = ["a"]\n', "a/x": ""})
        metadata = projects.load_metadata(root)
        self.assertEqual(metadata["roots"], [root, root / "a"])
        self.assertEqual(projects.session_label(root), f"Old - {root.name}")

    def test_legacy_one_line_yaml_file_is_read_instead_of_failing(self):
        root = self.make({".whc": "project: whc.fyi\n"})
        metadata = projects.load_metadata(root)
        self.assertEqual((metadata["root"], metadata["name"]), (root, "whc.fyi"))

    def test_project_key_in_legacy_toml_names_the_project(self):
        root = self.make({".whc": 'project = "Infra"\n'})
        self.assertEqual(projects.load_metadata(root)["name"], "Infra")

    def test_empty_whc_directory_is_not_a_project(self):
        root = self.make({"sub/.whc/local/ticket": "X-1\n", "sub/x": ""})
        self.assertFalse(projects.has_config(root / "sub"))
        self.assertEqual(projects.find_config_root(root / "sub"), root / "sub")

    def test_walk_up_does_not_stop_at_nested_git_roots(self):
        root = self.make({".whc/project.yml": "name: A\ncode: AA\n", "core/.git/HEAD": "", "core/src/x": ""})
        self.assertEqual(projects.find_config_root(root / "core" / "src"), root)

    def test_invalid_yaml_is_an_error(self):
        root = self.make({".whc/project.yml": "name: [unclosed\n"})
        try:
            import yaml  # noqa: F401  (the fallback parser is lenient by design)
        except ImportError:
            self.skipTest("PyYAML not installed")
        with self.assertRaisesRegex(ValueError, "Cannot read"):
            projects.load_metadata(root)

    def test_mini_yaml_matches_pyyaml_on_the_shapes_whc_uses(self):
        text = ('# comment\nname: Farmhand\ncode: FH\nlabels: [a, b]\nsession: "X - {{ ticket }}"\n'
                "repos:\n  core: {path: core, url: git@github.com:o/r.git}\nroots: [core]\n")
        try:
            import yaml
        except ImportError:
            self.skipTest("PyYAML not installed")
        self.assertEqual(projects.mini_yaml(text), yaml.safe_load(text))

    def test_picker_lists_workspace_members_such_as_farmhand_premium(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        base = Path(temp.name).resolve()
        for name in ("projects/farmhand/core", "projects/farmhand/premium", "projects/farmhand/mobile",
                     "projects/other", "dotfiles"):
            (base / name).mkdir(parents=True)
        (base / "projects/farmhand/.whc").mkdir()
        (base / "projects/farmhand/.whc/workspace.yml").write_text("roots: [core, premium]\n")
        env = {"WHC_DOTFILES_DIR": str(base / "dotfiles"), "WHC_PROTO_DIR": str(base / "prototypes")}
        root = base / "projects"
        with patch.dict(os.environ, env):
            labels = [projects.project_label(p, root) for p in projects.projects(root, base / "infra")]
        self.assertEqual(labels, ["dotfiles", "farmhand", "farmhand/core", "farmhand/premium", "other"])

    def test_prototypes_bucket_does_not_capture_the_prototypes_inside_it(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        base = Path(temp.name).resolve()
        (base / "prototypes/.whc").mkdir(parents=True)
        (base / "prototypes/.whc/project.yml").write_text("name: Prototypes\ncode: PROTO\n")
        (base / "prototypes/vice").mkdir()
        with patch.dict(os.environ, {"WHC_PROTO_DIR": str(base / "prototypes")}):
            self.assertEqual(projects.find_config_root(base / "prototypes" / "vice"), base / "prototypes" / "vice")
            self.assertEqual(projects.find_config_root(base / "prototypes"), base / "prototypes")


class WorkspaceTerminalTests(unittest.TestCase):
    def test_compositor_selection(self):
        instances = [
            {"instance": "current", "wl_socket": "wayland-1"},
            {"instance": "other", "wl_socket": "wayland-2"},
        ]
        cases = [
            ({"HYPRLAND_INSTANCE_SIGNATURE": "other", "WAYLAND_DISPLAY": "wayland-1"}, instances, "other"),
            ({"HYPRLAND_INSTANCE_SIGNATURE": "stale", "WAYLAND_DISPLAY": "wayland-1"}, instances, "current"),
            ({"WAYLAND_DISPLAY": "wayland-1"}, instances, "current"),
            ({"HYPRLAND_INSTANCE_SIGNATURE": "stale"}, instances[:1], "current"),
            ({}, instances, None),
            ({}, [], None),
        ]
        for env, running, expected in cases:
            with self.subTest(env=env, running=running), patch.dict(os.environ, env, clear=True), \
                    patch.object(projects.subprocess, "check_output", return_value=json.dumps(running)):
                self.assertEqual(projects.hyprland_command(), ["hyprctl", "-i", expected] if expected else None)

    def test_stale_launcher_reuses_terminal_on_active_workspace(self):
        def window(workspace, pid, address, focus):
            return dict(mapped=True, hidden=False, workspace={"id": workspace},
                        initialClass="foot", pid=pid, address=address, focusHistoryID=focus)

        replies = [
            json.dumps([{"instance": "current", "wl_socket": "wayland-1"}]),
            json.dumps({"id": 11}),
            json.dumps([window(12, 100, "elsewhere", 0), window(11, 200, "older", 2),
                        window(11, 300, "recent", 1)]),
        ]
        with patch.dict(os.environ, {"HYPRLAND_INSTANCE_SIGNATURE": "stale"}, clear=True), \
                patch.object(projects, "ensure_project", return_value="project"), \
                patch.object(projects.subprocess, "check_output", side_effect=replies) as query, \
                patch.object(projects, "tmux", return_value=Mock(stdout="101\t/dev/pts/1\n201\t/dev/pts/2\n301\t/dev/pts/3\n")) as tmux, \
                patch.object(projects, "process_ancestors", side_effect=lambda pid: {pid, pid - 1}), \
                patch.object(projects.subprocess, "run") as run, \
                patch.object(projects.subprocess, "Popen") as spawn:
            projects.open_project(Path("/project"))
            tmux.assert_called_with("switch-client", "-c", "/dev/pts/3", "-t", "=project")
            run.assert_called_once_with(["hyprctl", "-i", "current", "dispatch", "focuswindow", "address:recent"], check=True)
            self.assertEqual(query.call_args_list[1].args[0], ["hyprctl", "-i", "current", "-j", "activeworkspace"])
            spawn.assert_not_called()

    def test_no_workspace_terminal_opens_new_terminal(self):
        with patch.dict(os.environ, {}, clear=True), \
                patch.object(projects, "ensure_project", return_value="project"), \
                patch.object(projects, "workspace_terminal", return_value=None), \
                patch.object(projects.subprocess, "Popen") as spawn:
            projects.open_project(Path("/project"))
            spawn.assert_called_once_with(["foot", "tmux", "attach-session", "-t", "=project"], start_new_session=True)

    def test_terminal_open_attaches_in_current_terminal(self):
        with patch.dict(os.environ, {}, clear=True), \
                patch.object(projects, "ensure_project", return_value="Foo - TK-1234"), \
                patch.object(projects.os, "execvp") as execute:
            projects.open_project(Path("/project"), graphical=False)
            execute.assert_called_once_with(
                "tmux", ["tmux", "attach-session", "-t", "=Foo - TK-1234"])


if __name__ == "__main__":
    unittest.main()
