#!/usr/bin/env python3
"""Reconcile owned mpvpaper players. Called on state changes, never polled."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time

VIDEO_EXTENSIONS = {".mp4", ".webm", ".mkv", ".avi", ".mov"}


def is_video(path):
    return Path(path).suffix.lower() in VIDEO_EXTENSIONS


def send(path, command):
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(0.2)
        client.connect(str(path))
        client.sendall((json.dumps({"command": command}) + "\n").encode())


def alive(player):
    try:
        cmdline = (Path("/proc") / str(player["pid"]) / "cmdline").read_bytes().split(b"\0")
        return Path(os.fsdecode(cmdline[0])).name == "mpvpaper" and os.fsencode(player["socket"]) in b" ".join(cmdline)
    except (OSError, KeyError):
        return False


def stop(player):
    if not alive(player):
        return
    try:
        send(player["socket"], ["quit"])
    except OSError:
        os.kill(player["pid"], signal.SIGTERM)
    for _ in range(20):
        if not alive(player):
            break
        time.sleep(0.025)


def validate(entries):
    if not isinstance(entries, list) or len(entries) > 16:
        raise ValueError("Invalid live wallpaper list")
    names = set()
    for entry in entries:
        if not isinstance(entry["monitor"], str) or not entry["monitor"] or entry["monitor"] in names:
            raise ValueError("Invalid display")
        names.add(entry["monitor"])
        if not is_video(entry["path"]) or not Path(entry["path"]).is_absolute() or not Path(entry["path"]).is_file():
            raise ValueError("Choose an existing local video")
        if type(entry["fps"]) is not int or not 10 <= entry["fps"] <= 30:
            raise ValueError("Wallpaper frame rate must be between 10 and 30")
        if type(entry["paused"]) is not bool:
            raise ValueError("Invalid playback state")
    return entries


def sync(entries):
    validate(entries)
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime:
        raise ValueError("A Wayland runtime directory is required")
    directory = Path(runtime) / "ii-live-wallpaper"
    directory.mkdir(mode=0o700, exist_ok=True)
    registry = directory / "players.json"
    errors = []
    with (directory / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        players = json.loads(registry.read_text()) if registry.exists() else {}
        wanted = {entry["monitor"]: entry for entry in entries}
        for name, player in list(players.items()):
            entry = wanted.get(name)
            if not entry or (entry["path"], entry["fps"]) != (player["path"], player["fps"]) or not alive(player):
                stop(player)
                del players[name]
        for name, entry in wanted.items():
            player = players.get(name)
            try:
                if not player:
                    ipc = directory / (hashlib.sha256(name.encode()).hexdigest()[:12] + ".sock")
                    ipc.unlink(missing_ok=True)
                    # Frame conversion is capped, no interpolation/audio/scripts, hardware decoding preferred.
                    options = (f'no-config no-audio terminal=no loop-file=inf hwdec=auto-safe load-scripts=no '
                               f'interpolation=no vd-lavc-threads=2 video-sync=audio scale=bilinear dscale=bilinear '
                               f'vf=fps={entry["fps"]} input-ipc-server={ipc} '
                               f'pause={"yes" if entry["paused"] else "no"}')
                    with (directory / "player.log").open("w") as log:
                        process = subprocess.Popen(["mpvpaper", "-o", options, name, entry["path"]],
                                                   stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True)
                    player = dict(entry, pid=process.pid, socket=str(ipc))
                    for _ in range(40):
                        if ipc.exists() or process.poll() is not None:
                            break
                        time.sleep(0.05)
                    if process.poll() is not None or not ipc.exists():
                        stop(player)
                        raise RuntimeError("mpvpaper could not start; check " + str(directory / "player.log"))
                    players[name] = player
                if player["paused"] != entry["paused"]:
                    send(player["socket"], ["set_property", "pause", entry["paused"]])
                    player["paused"] = entry["paused"]
            except (OSError, RuntimeError) as error:
                errors.append(str(error))
        temporary = directory / "players.tmp"
        temporary.write_text(json.dumps(players))
        temporary.replace(registry)
    if errors:
        raise RuntimeError("\n".join(errors))


if __name__ == "__main__":
    try:
        sync(json.load(sys.stdin))
    except (ValueError, KeyError, OSError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
