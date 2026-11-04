# Desktop controls

- **Settings → Displays:** drag displays into position and select a mode, scale,
  or rotation. Press Apply changes, then Keep within 15 seconds. Timeout, closing the
  preview process, or a failed apply restores the previous layout. Saved settings
  go into `~/.config/hypr/custom/shell-monitors.lua`; `monitors.lua` stays intact.
- **Settings → Startup:** opt in to commands, workspace assignments, and delays.
  These run once per Hyprland session, including when Quickshell is reloaded.
  Restart Hyprland for new startup entries to take effect. Existing exec commands
  are not imported automatically.
- **Settings → Battery:** view peripheral readings from Bluetooth and UPower,
  and configure low and critical UPower notifications. Peripheral percentages also
  appear in System icons, the vertical bar, and the battery popup. The Bluetooth
  device list already shows percentages for devices that report them.
- **Settings → Widgets:** enable desktop widgets, choose a display, and change
  their size. Unlock positions to drag them. Detailed styles remain in Background.
- **Settings → Appearance:** choose installed GTK, Qt, icon, cursor, application
  font, and shell font settings. Apply system changes explicitly; some apps need
  reopening. Wallpaper template switches create `matugen/shell-filtered.toml`;
  the original `matugen/config.toml` is preserved. Required shell templates stay on.
- **Launcher:** settings results appear alongside apps. Searches can match words
  across a setting's label, section, and page; choosing one opens its section.
- **Wallpaper picker → Online:** search Wallhaven SFW images with category,
  resolution, and sorting filters. Select an image to download and apply it.
  Downloads remain in `Pictures/Wallpapers/Online`. Network requests happen only
  on search, page changes, downloading, and loading visible thumbnails.
- **Wallpaper picker → Local:** includes video files as well as images.

Live wallpapers require `mpvpaper` and `ffmpeg`. Settings → Background contains
playback controls. The defaults are muted playback, a 24 fps output cap, hardware
decoding where supported, two software decoder threads, and pausing on battery.
Playback also pauses on lock, display power-off, and behind fullscreen windows.
Normal tiled windows do not pause playback. Settings shows the current pause reason. A manual pause remains in effect until resumed. Selecting an
image stops the shell's video players. Players are reconciled on state changes;
there is no periodic wallpaper polling process. Each display has its own player.
Use modest-resolution clips: actual CPU/GPU use still depends on codec, resolution,
driver support, and the number of displays.

The Python helpers use the standard library (Python 3.11+). Appearance controls
also use the existing `gsettings`, Fontconfig, and KDE platform theme integration.
The new Hyprland display/startup/cursor hooks must be installed along with the
Quickshell files; updating only the shell directory is insufficient.

Settings pages share grouped rows, wrapping labels and choices, and adaptive input
fields. The navigation scrolls independently below the profile and Config file
button in both the overlay and standalone settings window.

Run backend checks from this directory:

```sh
python3 -m unittest discover -s tests -v
```

The display transaction tests mock `hyprctl`; they do not change physical displays.
Run `python3 tests/check_ui.py` in a Wayland session to check cached-page navigation,
wallpaper pause rules and thumbnail paths, peripheral reading deduplication, and
settings control alignment. Every settings page is rendered at normal and narrow
widths. The check opens isolated test windows using private settings under `/tmp`;
page screenshots and the log are saved to the printed `/tmp/ii-settings-review-*`
directory, with a control screenshot at `/tmp/ii-ui-regressions.png`.
