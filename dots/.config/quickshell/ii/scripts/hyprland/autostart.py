#!/usr/bin/env python3
"""Run configured startup apps once per compositor session, never on shell reload."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def validate(apps):
    if not isinstance(apps, list) or len(apps) > 100:
        raise ValueError("Invalid startup app list")
    for app in apps:
        if not isinstance(app.get("cmd"), str) or "\x00" in app["cmd"]:
            raise ValueError("Invalid startup command")
        if type(app.get("workspace")) is not int or not 0 <= app["workspace"] <= 100:
            raise ValueError("Workspace must be between 0 (current) and 100")
        if type(app.get("delay")) is not int or not 0 <= app["delay"] <= 300:
            raise ValueError("Delay must be between 0 and 300 seconds")
    return apps


def run():
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not signature or not runtime:
        return
    lock_path = Path(runtime) / ("ii-autostart-" + signature.replace("/", "_") + ".lock")
    with lock_path.open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        lock.seek(0)
        if lock.read():
            return
        config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "illogical-impulse/config.json"
        settings = json.loads(config.read_text()).get("hyprland", {}).get("autostartApps", {})
        apps = validate(settings.get("apps", [])) if settings.get("enable", False) else []
        lock.write("started\n")
        lock.flush()
    start = time.monotonic()
    for app in sorted(apps, key=lambda entry: entry["delay"]):
        if not app["cmd"].strip() or not app.get("enabled", True):
            continue
        time.sleep(max(0, start + app["delay"] - time.monotonic()))
        # Commands are deliberately user-authored shell commands, never downloaded data.
        dispatch = f'[workspace {app["workspace"]} silent] ' if app["workspace"] else ""
        subprocess.run(["hyprctl", "dispatch", "exec", dispatch + app["cmd"]], check=True, timeout=5)


if __name__ == "__main__":
    try:
        run()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
