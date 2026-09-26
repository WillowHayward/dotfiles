import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import patch, Mock


spec = importlib.util.spec_from_file_location("tmux_projects", Path(__file__).with_name("tmux-projects.py"))
projects = importlib.util.module_from_spec(spec)
spec.loader.exec_module(projects)


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


if __name__ == "__main__":
    unittest.main()
