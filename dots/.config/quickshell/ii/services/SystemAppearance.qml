pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    property var catalog: ({gtkThemes: [], iconThemes: [], cursorThemes: [], qtStyles: [], fonts: [], templates: []})
    property var draft: ({gtkTheme: "", iconTheme: "", cursorTheme: "", cursorSize: 24, font: "Sans 11", qtStyle: ""})
    property string error: ""
    property string message: ""
    readonly property bool busy: scan.running || applyProc.running
    function refresh() { if (!busy) { error = ""; scan.running = true; } }
    function setDraft(key, value) { const next = Object.assign({}, draft); next[key] = value; draft = next; }
    function regenerate() {
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/colors/switchwall.sh"), "--noswitch"]);
    }
    function apply() {
        if (busy) return;
        error = ""; message = "";
        applyProc.snapshot = Object.assign({}, draft);
        applyProc.stdinEnabled = true;
        applyProc.running = true;
    }
    Process {
        id: scan
        command: ["python3", Quickshell.shellPath("scripts/appearance.py"), "scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return;
                try {
                    const data = JSON.parse(text);
                    root.catalog = data;
                    const stored = Config.options.appearance.system;
                    const draft = data.current;
                    for (const key of ["gtkTheme", "iconTheme", "cursorTheme", "font", "qtStyle"]) {
                        if (stored[key]) draft[key] = stored[key];
                    }
                    draft.cursorSize = stored.cursorSize;
                    root.draft = draft;
                } catch (e) { root.error = "Could not read installed appearance settings"; }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
    }
    Process {
        id: applyProc
        property var snapshot
        command: ["python3", Quickshell.shellPath("scripts/appearance.py"), "apply"]
        onStarted: { write(JSON.stringify(snapshot)); stdinEnabled = false; }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
        onExited: code => {
            if (code !== 0) return;
            const stored = Config.options.appearance.system;
            for (const key of Object.keys(snapshot)) stored[key] = snapshot[key];
            root.message = Translation.tr("Applied. Reopen apps to pick up all theme changes.");
        }
    }
}
