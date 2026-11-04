pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root
    property bool manuallyPaused: false
    property string error: ""
    readonly property bool available: desired.length > 0
    readonly property bool powerPaused: Battery.available && UPower.onBattery
        && (Config.options.background.liveWallpaper.pauseOnBattery
            || Battery.percentage * 100 <= Config.options.background.liveWallpaper.pauseBelowPercent)
    readonly property bool paused: manuallyPaused || powerPaused || GlobalStates.screenLocked
    readonly property var pauseReasons: desired.filter(entry => entry.paused).map(entry => entry.reason)
    readonly property var desired: {
        if (!Config.ready) return [];
        return Quickshell.screens.map(screen => {
            const m = HyprlandData.monitors.find(m => m.name === screen.name);
            const entry = Config.options.background.multiMonitor.enable
                ? Config.options.background.wallpapersByMonitor.find(w => w.monitor === screen.name) : null;
            const path = entry?.path || Config.options.background.wallpaperPath;
            if (!isVideo(path)) return null;
            const covered = monitorCovered(m, HyprlandData.windowList);
            const unsafe = Config.options.workSafety.enable.wallpaper
                && Config.options.workSafety.triggerCondition.fileKeywords.some(k => path.toLowerCase().includes(k.toLowerCase()))
                && Config.options.workSafety.triggerCondition.networkNameKeywords.some(k => Network.networkName.toLowerCase().includes(k.toLowerCase()));
            if (unsafe) return null;
            return {monitor: screen.name, path: path, fps: Config.options.background.liveWallpaper.maxFps,
                paused: root.paused || covered,
                reason: root.manuallyPaused ? Translation.tr("Paused manually")
                    : root.powerPaused ? Translation.tr("Paused to save battery")
                    : GlobalStates.screenLocked ? Translation.tr("Paused while locked")
                    : covered ? Translation.tr("Paused while the display is covered or off") : ""};
        }).filter(Boolean);
    }
    function isVideo(path) { return /\.(mp4|webm|mkv|avi|mov)$/i.test(path || ""); }
    function previewPath(path) {
        if (!isVideo(path)) return path || "";
        return FileUtils.trimFileProtocol(Directories.config) + "/hypr/custom/scripts/mpvpaper_thumbnails/" + Qt.md5(path) + ".jpg";
    }
    function monitorCovered(monitor, windows) {
        if (!monitor) return false;
        if (monitor.dpmsStatus === false) return true;
        const workspaceIds = [monitor.activeWorkspace?.id, monitor.specialWorkspace?.id].filter(id => typeof id === "number" && id !== 0);
        return windows.some(w => !w.hidden && w.monitor === monitor.id && workspaceIds.includes(w.workspace?.id)
            && (w.fullscreen > 0 || (w.size?.[0] >= monitor.width / monitor.scale - 4
                && w.size?.[1] >= monitor.height / monitor.scale - 4)));
    }
    function load() { reconcile.restart(); }
    function toggle() { manuallyPaused = !manuallyPaused; }
    readonly property string requestedState: JSON.stringify(desired.map(entry => ({monitor: entry.monitor, path: entry.path, fps: entry.fps, paused: entry.paused})))
    onRequestedStateChanged: reconcile.restart()
    Timer {
        id: reconcile
        interval: 200
        onTriggered: {
            if (!Config.ready) return;
            if (worker.running) { restart(); return; }
            worker.stdinEnabled = true;
            worker.running = true;
        }
    }
    Process {
        id: worker
        command: ["python3", Quickshell.shellPath("scripts/wallpapers/live.py")]
        onStarted: {
            root.error = "";
            write(JSON.stringify(root.desired));
            stdinEnabled = false;
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
    }
    IpcHandler {
        target: "liveWallpaper"
        function toggle(): void { root.toggle(); }
    }
}
