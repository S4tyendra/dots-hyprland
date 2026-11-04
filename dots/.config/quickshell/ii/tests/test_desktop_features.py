"""Run with: python3 -m unittest discover -s tests -v (from the ii directory)."""
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import hashlib
import shutil
import subprocess
import unittest
from unittest.mock import Mock, patch

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"


def load(name, relative):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


displays = load("displays", "hyprland/displays.py")
startup = load("autostart", "hyprland/autostart.py")
appearance = load("appearance", "appearance.py")
online = load("online", "wallpapers/online.py")
live = load("live", "wallpapers/live.py")


class DisplaysTest(unittest.TestCase):
    def setUp(self):
        self.layout = [dict(name="DP-1", mode="1920x1080@60", x=0, y=0, scale=1, transform=0, disabled=False)]

    def test_rejects_invalid_layout_before_apply(self):
        for key, value in (("name", 'DP-1\",disable'), ("mode", "preferred,auto,1"), ("scale", float("nan")),
                           ("scale", 0), ("transform", 9), ("x", 0.5)):
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                displays.validate([{**self.layout[0], key: value}])

    def test_keep_persists_after_preview(self):
        with patch.object(displays, "current_layout", return_value=self.layout), patch.object(displays, "apply") as apply, \
             patch.object(displays, "persist") as persist, patch.object(displays.select, "select", return_value=([1], [], [])), \
             patch.object(displays.sys, "stdin", io.StringIO("keep\n")), patch.object(displays.sys, "stdout", io.StringIO()):
            displays.preview(self.layout)
            persist.assert_called_once_with(self.layout)
            apply.assert_called_once_with(self.layout)

    def test_timeout_and_eof_revert_without_saving(self):
        for ready in ([], [1]):
            previous = [{**self.layout[0], "x": 100}]
            with patch.object(displays, "current_layout", return_value=previous), patch.object(displays, "apply") as apply, \
                 patch.object(displays, "persist") as persist, patch.object(displays.select, "select", return_value=(ready, [], [])), \
                 patch.object(displays.sys, "stdin", io.StringIO()), patch.object(displays.sys, "stdout", io.StringIO()):
                displays.preview(self.layout)
                self.assertEqual(apply.call_args_list[-1].args[0], previous)
                persist.assert_not_called()

    def test_failed_apply_restores_previous_layout(self):
        with patch.object(displays, "current_layout", return_value=self.layout), \
             patch.object(displays, "apply", side_effect=[RuntimeError("invalid mode"), None]) as apply:
            with self.assertRaises(RuntimeError):
                displays.preview(self.layout)
            self.assertEqual(apply.call_count, 2)

    def test_save_preserves_user_monitor_file(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, XDG_CONFIG_HOME=directory):
            original = Path(directory) / "hypr/monitors.lua"
            original.parent.mkdir()
            original.write_text("-- my settings\n")
            displays.persist(self.layout)
            self.assertEqual(original.read_text(), "-- my settings\n")
            self.assertIn('output = "DP-1"', (original.parent / "custom/shell-monitors.lua").read_text())

    def test_apply_uses_lua_and_checks_actual_display_state(self):
        with patch.object(displays.subprocess, "run", return_value=Mock(returncode=0, stdout="ok\n")) as run, \
             patch.object(displays, "current_layout", return_value=self.layout) as read:
            displays.apply(self.layout)
            self.assertEqual(run.call_args.args[0][:2], ["hyprctl", "eval"])
            self.assertIn("hl.monitor({", run.call_args.args[0][2])
            self.assertIn("transform = 0", run.call_args.args[0][2])
            read.assert_called_once()

    def test_silent_mode_rejection_fails_instead_of_reporting_success(self):
        rejected = [{**self.layout[0], "transform": 1}]
        with patch.object(displays.subprocess, "run", return_value=Mock(returncode=0, stdout="ok\n")), \
             patch.object(displays, "current_layout", return_value=self.layout), \
             patch.object(displays.time, "monotonic", side_effect=[0, 4]):
            with self.assertRaisesRegex(RuntimeError, "did not accept"):
                displays.apply(rejected)

    def test_layout_check_handles_hertz_rounding_and_rotation(self):
        actual = [{**self.layout[0], "mode": "1920x1080@60.056"}]
        self.assertTrue(displays.layout_matches(self.layout, actual))
        self.assertFalse(displays.layout_matches([{**self.layout[0], "mode": "1920x1080@40.04Hz"}], actual))
        self.assertFalse(displays.layout_matches([{**self.layout[0], "transform": 1}], actual))


class AppearanceTest(unittest.TestCase):
    def test_ini_preserves_other_sections_comments_and_values(self):
        source = "# user settings\n[Settings]\nother=value\ngtk-theme-name=Old\n[Other]\nkey=keep\n"
        result = appearance.set_ini(source, "Settings", "gtk-theme-name", "New")
        self.assertIn("# user settings", result)
        self.assertIn("other=value", result)
        self.assertIn("[Other]\nkey=keep", result)
        self.assertIn("gtk-theme-name=New", result)
        self.assertNotIn("Old", result)

    def test_ini_insertion_has_correct_section_and_newline(self):
        self.assertEqual(appearance.set_ini("[Settings]\nother=keep", "Settings", "theme", "New"), "[Settings]\nother=keep\ntheme=New\n")
        with self.assertRaises(ValueError):
            appearance.set_ini("", "Settings", "theme", "bad\nkey=evil")

    def test_template_filter_keeps_required_and_nested_blocks(self):
        source = '[config]\nversion_check=false\n[templates.m3colors]\ninput_path="a"\n[templates.gtk3]\ninput_path="b"\n[templates.gtk3.extra]\nx=1\n[templates.wallpaper]\ninput_path="c"\n'
        result = appearance.filtered_config(source, ["gtk3"])
        self.assertNotIn("templates.gtk3", result)
        self.assertIn("templates.m3colors", result)
        self.assertIn("templates.wallpaper", result)
        self.assertEqual(appearance.filtered_config(source, []), source)
        for disabled in (["m3colors"], ["wallpaper"], ["missing"]):
            with self.assertRaises(ValueError):
                appearance.filtered_config(source, disabled)


class WallpaperTest(unittest.TestCase):
    def test_download_rejects_untrusted_urls(self):
        for url in ("http://w.wallhaven.cc/a", "https://evil.test/a", "file:///etc/passwd", "https://w.wallhaven.cc.evil/a", "https://user@w.wallhaven.cc/a"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                online.validate_url(url, "w.wallhaven.cc")

    def test_download_never_replaces_file_on_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "wallhaven-abcdef.jpg"
            path.write_bytes(b"existing")
            response = Mock()
            response.__enter__ = Mock(return_value=response)
            response.__exit__ = Mock(return_value=False)
            response.headers = Mock()
            response.headers.get.return_value = "0"
            response.headers.get_content_type.return_value = "image/jpeg"
            response.read.side_effect = [b"partial", OSError("network lost")]
            with patch.object(online, "request", return_value=response), self.assertRaises(OSError):
                online.download("https://w.wallhaven.cc/full/ab/wallhaven-abcdef.jpg", directory)
            self.assertEqual(path.read_bytes(), b"existing")
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_download_limit_and_search_validation(self):
        for args in (("q", 0, "relevance", "", "111"), ("q", 1, "evil", "", "111"), ("q", 1, "relevance", "invalid", "111")):
            with self.assertRaises(ValueError):
                online.search(*args)

    def test_download_rejects_oversized_and_nonimage_payloads(self):
        for content_length, payload in ((str(online.MAX_DOWNLOAD + 1), b""), ("0", b"<html>not an image</html>")):
            with tempfile.TemporaryDirectory() as directory:
                response = Mock()
                response.__enter__ = Mock(return_value=response)
                response.__exit__ = Mock(return_value=False)
                response.headers.get.return_value = content_length
                response.headers.get_content_type.return_value = "image/jpeg"
                response.read.side_effect = [payload, b""]
                with patch.object(online, "request", return_value=response), self.assertRaises(ValueError):
                    online.download("https://w.wallhaven.cc/full/ab/wallhaven-abcdef.jpg", directory)
                self.assertEqual(list(Path(directory).iterdir()), [])

    @unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg not installed")
    def test_video_thumbnail_with_spaces_uses_xdg_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            video = Path(directory) / "a video's test.mp4"
            subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "color=c=blue:s=160x90:d=0.1", "-threads", "1", str(video)], check=True)
            cache = Path(directory) / "cache"
            subprocess.run(["bash", str(SCRIPTS / "thumbnails/generate-thumbnails-magick.sh"), "--size", "normal", "--file", str(video)],
                           check=True, env={**os.environ, "XDG_CACHE_HOME": str(cache)})
            # Match ThumbnailImage.qml's percent-encoded file URI, including apostrophes.
            from urllib.parse import quote
            uri = "file://" + quote(str(video), safe="/~()*!.'-_")
            thumbnail = cache / "thumbnails/normal" / (hashlib.md5(uri.encode()).hexdigest() + ".png")
            self.assertTrue(thumbnail.is_file())
            self.assertTrue(thumbnail.read_bytes().startswith(b"\x89PNG"))

    def test_live_validation_and_case_insensitive_video(self):
        self.assertTrue(live.is_video("/tmp/Wallpaper.MP4"))
        self.assertFalse(live.is_video("/tmp/photo.jpg"))
        with tempfile.NamedTemporaryFile(suffix=".mp4") as video:
            entry = dict(monitor="DP-1", path=video.name, fps=24, paused=True)
            self.assertEqual(live.validate([entry]), [entry])
            for key, value in (("fps", 120), ("path", "https://evil.test/a.mp4"), ("paused", "false")):
                with self.assertRaises(ValueError):
                    live.validate([{**entry, key: value}])

    def test_live_reuses_player_and_only_sends_pause_changes(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.NamedTemporaryFile(suffix=".mp4") as video, \
             patch.dict(os.environ, XDG_RUNTIME_DIR=directory), patch.object(live, "alive", return_value=True), \
             patch.object(live, "send") as send, patch.object(live.subprocess, "Popen") as spawn:
            state = Path(directory) / "ii-live-wallpaper"
            state.mkdir()
            entry = dict(monitor="DP-1", path=video.name, fps=24, paused=False)
            (state / "players.json").write_text(json.dumps({"DP-1": dict(entry, pid=1234, socket="/tmp/test.sock")}))
            live.sync([entry])
            spawn.assert_not_called()
            send.assert_not_called()
            live.sync([{**entry, "paused": True}])
            send.assert_called_once_with("/tmp/test.sock", ["set_property", "pause", True])
            live.sync([])
            self.assertEqual(send.call_args.args[1], ["quit"])


class StartupTest(unittest.TestCase):
    def test_startup_validation(self):
        self.assertEqual(startup.validate([dict(cmd="firefox", workspace=2, delay=5)])[0]["cmd"], "firefox")
        for app in (dict(cmd="bad\0", workspace=0, delay=0), dict(cmd="app", workspace=-1, delay=0), dict(cmd="app", workspace=0, delay=301)):
            with self.assertRaises(ValueError):
                startup.validate([app])

    def test_startup_runs_once_per_session(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, XDG_CONFIG_HOME=directory, XDG_RUNTIME_DIR=directory, HYPRLAND_INSTANCE_SIGNATURE="test-session"), \
             patch.object(startup.subprocess, "run") as run:
            config = Path(directory) / "illogical-impulse/config.json"
            config.parent.mkdir()
            config.write_text(json.dumps({"hyprland": {"autostartApps": {"enable": True, "apps": [dict(cmd="firefox", workspace=2, delay=0)]}}}))
            startup.run()
            startup.run()
            run.assert_called_once()
            self.assertEqual(run.call_args.args[0], ["hyprctl", "dispatch", "exec", "[workspace 2 silent] firefox"])


if __name__ == "__main__":
    unittest.main()
