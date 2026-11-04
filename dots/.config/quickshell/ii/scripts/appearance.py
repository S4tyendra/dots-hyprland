#!/usr/bin/env python3
"""Installed appearance settings and a filtered copy of the user's Matugen config."""
import ast
import configparser
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import tomllib

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
DATA = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(text)
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def set_ini(text, section, key, value):
    if any(c in str(value) for c in "\n\r\0"):
        raise ValueError("Invalid appearance setting")
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.read_string(text)
    lines = text.splitlines(keepends=True)
    start = next((i for i, line in enumerate(lines) if line.strip() == f"[{section}]"), None)
    if start is None:
        return text.rstrip() + f"\n[{section}]\n{key}={value}\n"
    end = next((i for i in range(start + 1, len(lines)) if lines[i].lstrip().startswith("[")), len(lines))
    indices = [i for i in range(start + 1, end) if re.match(r"\s*" + re.escape(key) + r"\s*=", lines[i])]
    if indices:
        for i in indices:
            lines[i] = f"{key}={value}\n"
    else:
        if lines and not lines[end - 1].endswith("\n"):
            lines[end - 1] += "\n"
        lines.insert(end, f"{key}={value}\n")
    return "".join(lines)


def write_ini(path, section, key, value):
    atomic_write(path, set_ini(path.read_text() if path.exists() else "", section, key, value))


def gget(key, fallback=""):
    result = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", key], capture_output=True, text=True, timeout=5)
    try:
        return ast.literal_eval(result.stdout.strip()) if result.returncode == 0 else fallback
    except (ValueError, SyntaxError):
        return fallback


def scan():
    icons = [DATA / "icons", Path.home() / ".icons", Path("/usr/local/share/icons"), Path("/usr/share/icons")]
    themes = [DATA / "themes", Path.home() / ".themes", Path("/usr/local/share/themes"), Path("/usr/share/themes")]
    directories = lambda bases: [p for base in bases if base.is_dir() for p in base.iterdir() if p.is_dir()]
    icon_dirs = directories(icons)
    source = CONFIG / "matugen/config.toml"
    templates = list(tomllib.loads(source.read_text()).get("templates", {})) if source.exists() else []
    fonts = subprocess.check_output(["fc-list", ":", "family"], text=True, timeout=10)
    styles = ["Fusion"]
    for style in ("breeze", "kvantum"):
        if list(Path("/usr/lib/qt6/plugins/styles").glob(f"*{style}*")):
            styles.append(style)
    kde = configparser.ConfigParser(interpolation=None, strict=False)
    kde.read(CONFIG / "kdeglobals")
    return dict(gtkThemes=sorted({p.name for p in directories(themes) if (p / "gtk-3.0").is_dir()}),
                iconThemes=sorted({p.name for p in icon_dirs if (p / "index.theme").exists() and not (p / "cursors").is_dir()}),
                cursorThemes=sorted({p.name for p in icon_dirs if (p / "cursors").is_dir()}),
                fonts=sorted({family.strip() for line in fonts.splitlines() for family in line.split(",")}),
                qtStyles=styles, templates=[name for name in templates if name not in ("m3colors", "wallpaper")],
                current=dict(gtkTheme=gget("gtk-theme"), iconTheme=gget("icon-theme"), cursorTheme=gget("cursor-theme"),
                             cursorSize=gget("cursor-size", 24), font=gget("font-name", "Sans 11"),
                             qtStyle=kde.get("KDE", "widgetStyle", fallback="breeze" if "breeze" in styles else "Fusion")))


def apply(settings):
    installed = scan()
    for key, catalog in (("gtkTheme", "gtkThemes"), ("iconTheme", "iconThemes"), ("cursorTheme", "cursorThemes"), ("qtStyle", "qtStyles")):
        if settings.get(key) and settings[key] not in installed[catalog] and settings[key] != installed["current"][key]:
            raise ValueError("Choose an installed " + key)
    if type(settings["cursorSize"]) is not int or not 16 <= settings["cursorSize"] <= 96:
        raise ValueError("Cursor size must be between 16 and 96")
    font = re.fullmatch(r"(.+?) (\d+(?:\.\d+)?)(?: @[-\w=,.+]+)?", settings.get("font", ""))
    if not font or not 6 <= float(font[2]) <= 72 or any(c in settings["font"] for c in "\n\r\0"):
        raise ValueError("Choose a font family and size")
    for key, gkey, ini_key in (("gtkTheme", "gtk-theme", "gtk-theme-name"), ("iconTheme", "icon-theme", "gtk-icon-theme-name"),
                                ("cursorTheme", "cursor-theme", "gtk-cursor-theme-name"), ("cursorSize", "cursor-size", "gtk-cursor-theme-size"),
                                ("font", "font-name", "gtk-font-name")):
        value = settings.get(key)
        if value in (None, ""):
            continue
        for version in (3, 4):
            write_ini(CONFIG / f"gtk-{version}.0/settings.ini", "Settings", ini_key, value)
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", gkey, str(value)], check=True, timeout=5)
    if settings.get("iconTheme"):
        write_ini(CONFIG / "kdeglobals", "Icons", "Theme", settings["iconTheme"])
    if settings.get("qtStyle"):
        write_ini(CONFIG / "kdeglobals", "KDE", "widgetStyle", settings["qtStyle"])
    write_ini(CONFIG / "kdeglobals", "General", "font", f"{font[1]},{font[2]},-1,5,50,0,0,0,0,0")
    if settings.get("cursorTheme"):
        write_ini(DATA / "icons/default/index.theme", "Icon Theme", "Inherits", settings["cursorTheme"])
        subprocess.run(["hyprctl", "setcursor", settings["cursorTheme"], str(settings["cursorSize"])], check=True, timeout=5)


def filtered_config(source, disabled):
    data = tomllib.loads(source)
    if not set(disabled) <= set(data.get("templates", {})) or set(disabled) & {"m3colors", "wallpaper"}:
        raise ValueError("Unknown or required Matugen template")
    output = []
    skip = False
    for line in source.splitlines(keepends=True):
        header = re.match(r"\s*\[(?!\[)([^\]]+)\]", line)
        if header:
            name = header[1]
            skip = any(name == f"templates.{key}" or name.startswith(f"templates.{key}.") for key in disabled)
        if not skip:
            output.append(line)
    result = "".join(output)
    parsed = tomllib.loads(result)
    if set(parsed.get("templates", {})) != set(data.get("templates", {})) - set(disabled):
        raise ValueError("Unsupported template names; edit the Matugen config directly")
    return result


def matugen_config():
    source = CONFIG / "matugen/config.toml"
    preferences = CONFIG / "illogical-impulse/config.json"
    disabled = json.loads(preferences.read_text()).get("appearance", {}).get("disabledTemplates", []) if preferences.exists() else []
    if not disabled:
        return str(source)
    generated = CONFIG / "matugen/shell-filtered.toml"
    atomic_write(generated, filtered_config(source.read_text(), disabled))
    return str(generated)


if __name__ == "__main__":
    try:
        action = sys.argv[1]
        if action == "scan":
            print(json.dumps(scan()))
        elif action == "apply":
            apply(json.load(sys.stdin))
        elif action == "matugen-config":
            print(matugen_config())
        elif action == "cursor":
            settings = json.loads((CONFIG / "illogical-impulse/config.json").read_text()).get("appearance", {}).get("system", {})
            subprocess.run(["hyprctl", "setcursor", settings.get("cursorTheme") or "Bibata-Modern-Classic", str(settings.get("cursorSize", 24))], check=True, timeout=5)
        else:
            raise ValueError("Unknown appearance action")
    except (ValueError, KeyError, OSError, configparser.Error, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
