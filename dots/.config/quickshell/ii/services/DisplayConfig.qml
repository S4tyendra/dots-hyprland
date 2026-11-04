pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var monitors: []
    property string error: ""
    property bool previewing: false
    property bool dirty: false
    readonly property bool busy: query.running || transaction.running
    property int secondsLeft: 15

    function refresh() {
        if (busy) return;
        error = "";
        query.running = true;
    }
    function update(index, key, value) {
        if (monitors[index][key] === value) return;
        const next = monitors.map(m => Object.assign({}, m));
        next[index][key] = value;
        monitors = next;
        dirty = true;
    }
    function preview() {
        if (busy || monitors.length === 0) return;
        error = "";
        transaction.stdinEnabled = true;
        transaction.running = true;
    }
    function finish(keep) {
        if (!previewing) return;
        previewing = false;
        transaction.write(keep ? "keep\n" : "revert\n");
        transaction.stdinEnabled = false;
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.previewing
        onTriggered: root.secondsLeft = Math.max(0, root.secondsLeft - 1)
    }
    Process {
        id: query
        command: ["python3", Quickshell.shellPath("scripts/hyprland/displays.py"), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).filter(m => !m.disabled);
                    root.dirty = false;
                }
                catch (e) { root.error = "Could not read connected displays"; }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
    }
    Process {
        id: transaction
        command: ["python3", Quickshell.shellPath("scripts/hyprland/displays.py"), "preview"]
        onStarted: write(JSON.stringify(root.monitors) + "\n")
        stdout: SplitParser {
            onRead: line => {
                try {
                    const state = JSON.parse(line);
                    if (state.preview) { root.secondsLeft = 15; root.previewing = true; }
                } catch (e) { root.error = "Could not preview display layout"; }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
        onExited: {
            root.previewing = false;
            Qt.callLater(() => { query.running = true; });
        }
    }
}
