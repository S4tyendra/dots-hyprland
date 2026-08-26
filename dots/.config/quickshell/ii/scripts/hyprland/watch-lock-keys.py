#!/usr/bin/env python3
"""Watch the main Hyprland keyboard for Caps/Num Lock changes.

Prints "caps num" (0/1) whenever the lock state changes, including the
initial state. Intended to be consumed by HyprlandXkb.qml.
"""
import json
import os
import subprocess
import sys
import time

INTERVAL_S = 0.15


def lock_state():
    raw = subprocess.check_output(
        ["hyprctl", "-j", "devices"],
        stderr=subprocess.DEVNULL,
    )
    data = json.loads(raw)
    keyboards = data.get("keyboards") or []
    if not keyboards:
        return None
    keyboard = next((kb for kb in keyboards if kb.get("main")), keyboards[0])
    return (
        1 if keyboard.get("capsLock") else 0,
        1 if keyboard.get("numLock") else 0,
    )


def main():
    previous = None
    parent = os.getppid()
    while True:
        if os.getppid() != parent:
            return
        try:
            state = lock_state()
        except (OSError, subprocess.CalledProcessError, json.JSONDecodeError, ValueError):
            state = None
        if state is not None and state != previous:
            previous = state
            print(f"{state[0]} {state[1]}", flush=True)
        time.sleep(INTERVAL_S)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
