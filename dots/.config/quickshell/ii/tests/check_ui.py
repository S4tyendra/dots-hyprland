#!/usr/bin/env python3
"""Exercise real QML controls with private settings and no compositor mutations."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

shell = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="ii-ui-check-", dir="/tmp") as directory:
    root = Path(directory)
    for name in ("modules", "services", "assets", "scripts", "defaults", "translations", "GlobalStates.qml"):
        (root / name).symlink_to(shell / name)
    shutil.copyfile(shell / "tests/ui-regressions.qml", root / "shell.qml")
    runtime = root / "runtime"
    runtime.mkdir(mode=0o700)
    config = root / "config/illogical-impulse/config.json"
    config.parent.mkdir(parents=True)
    config.write_text(json.dumps({
        "background": {"wallpaperPath": "", "widgets": {"clock": {"style": "digital", "styleLocked": "cookie"}, "visualizer": {"enable": True, "mode": "wave"}}},
        "hyprland": {"autostartApps": {"apps": [{"cmd": "firefox", "workspace": 2, "delay": 5}]}},
    }))
    (root / "screenshots").mkdir()
    matugen = root / "config/matugen/config.toml"
    matugen.parent.mkdir()
    matugen.write_text('[config]\nversion_check=false\n[templates.gtk3]\ninput_path="unused"\noutput_path="unused"\n')
    colors = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "quickshell/user/generated/colors.json"
    if colors.exists():
        target = root / "state/quickshell/user/generated/colors.json"
        target.parent.mkdir(parents=True)
        shutil.copyfile(colors, target)
    env = {**os.environ, "QT_QPA_PLATFORM": "wayland", "HYPRLAND_INSTANCE_SIGNATURE": "", "XDG_RUNTIME_DIR": str(runtime),
           "XDG_CONFIG_HOME": str(root / "config"), "XDG_CACHE_HOME": str(root / "cache"),
           "XDG_STATE_HOME": str(root / "state"), "XDG_DATA_HOME": str(root / "data")}
    display = Path(os.environ.get("WAYLAND_DISPLAY", "wayland-0"))
    env["WAYLAND_DISPLAY"] = str(display if display.is_absolute() else Path(os.environ["XDG_RUNTIME_DIR"]) / display)
    try:
        result = subprocess.run(["qs", "-p", str(root), "--no-color"], env=env, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired as error:
        print(error.stdout.decode(errors="replace") if isinstance(error.stdout, bytes) else error.stdout)
        raise SystemExit("UI regression process timed out")
    output = result.stdout + result.stderr
    binding_errors = ("TypeError:", "ReferenceError:", "is not a type", "Cannot assign", "anchors on an item")
    passed = (not any(marker in output for marker in binding_errors) and result.returncode == 0 and "UI REGRESSIONS PASS" in output
              and "UI REGRESSION FAIL" not in output and "Detected recursive rearrange" not in output)
    if passed:
        print("UI regression checks passed: all settings pages, compact layouts, sidebar scrolling, live-wallpaper policy, previews, and peripheral readings.")
    else:
        markers = ("UI REGRESSION", "Detected recursive", "is not a type", "ReferenceError", "TypeError", "ERROR", "Cannot assign", "anchors on an item")
        print("\n".join(dict.fromkeys(line for line in output.splitlines() if any(marker in line for marker in markers))))
    artifacts = Path(tempfile.mkdtemp(prefix="ii-settings-review-", dir="/tmp"))
    shutil.copytree(root / "screenshots", artifacts, dirs_exist_ok=True)
    (artifacts / "run.log").write_text(output)
    Path("/tmp/ii-settings-review-path").write_text(str(artifacts))
    print("Screenshots:", artifacts)
    if passed and (root / "regression.png").exists():
        shutil.copyfile(root / "regression.png", "/tmp/ii-ui-regressions.png")
    raise SystemExit(0 if passed else 1)
