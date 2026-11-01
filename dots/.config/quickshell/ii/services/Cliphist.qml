pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // property string cliphistBinary: FileUtils.trimFileProtocol(`${Directories.home}/.cargo/bin/stash`)
    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []

    // Pinned entries are copies of the decoded clipboard content, stored in
    // Directories.cliphistPinsDir. They survive `cliphist wipe` and history
    // pruning. Shape: { id, file, source, preview, isImage, width, height }
    property var pins: []
    property string pinsDir: Directories.cliphistPinsDir
    property string pinsIndexPath: Directories.cliphistPinsIndex
    property bool pinsLoaded: false
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        if (search.trim() === "") {
            return entries;
        }
        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry))
    }

    function entryImageDimensions(entry) {
        const match = entry?.match(/(\d+)x(\d+)/)
        return match ? { width: parseInt(match[1]), height: parseInt(match[2]) } : { width: 0, height: 0 }
    }

    function entryPreview(entry) {
        if (entryIsImage(entry)) {
            const dims = entryImageDimensions(entry)
            return dims.width > 0 ? `${Translation.tr("Image")} ${dims.width}x${dims.height}` : Translation.tr("Image")
        }
        return StringUtils.cleanCliphistEntry(entry)
    }

    function isPinned(entry) {
        return root.pinForEntry(entry) !== null
    }

    function pinForEntry(entry) {
        const preview = entryPreview(entry)
        for (let i = 0; i < root.pins.length; i++) {
            const pin = root.pins[i]
            if (pin.source === entry || (!pin.isImage && pin.preview === preview))
                return pin
        }
        return null
    }

    function pin(entry) {
        if (!entry || root.isPinned(entry))
            return
        const id = `${Date.now()}`
        const dims = entryImageDimensions(entry)
        pinProc.begin(entry, {
            id: id,
            file: `${root.pinsDir}/${id}`,
            source: entry,
            preview: root.entryPreview(entry),
            isImage: root.entryIsImage(entry),
            width: dims.width,
            height: dims.height
        })
    }

    function unpin(pin) {
        if (!pin)
            return
        root.pins = root.pins.filter(item => item.id !== pin.id)
        savePins()
        Quickshell.execDetached(["bash", "-c", `rm -f '${StringUtils.shellSingleQuoteEscape(pin.file)}'`])
    }

    function savePins() {
        if (!root.pinsLoaded)
            return
        pinsFileView.setText(JSON.stringify(root.pins))
    }

    function copyPin(pin) {
        if (!pin)
            return
        Quickshell.execDetached(["bash", "-c", `cat '${StringUtils.shellSingleQuoteEscape(pin.file)}' | wl-copy`])
    }

    function pastePin(pin) {
        if (!pin)
            return
        Quickshell.execDetached(["bash", "-c", `cat '${StringUtils.shellSingleQuoteEscape(pin.file)}' | wl-copy; ${root.pressPasteCommand}`])
    }

    function fuzzyQueryPinned(search: string): var {
        if (search.trim() === "")
            return root.pins
        const prepared = root.pins.map(pin => ({
            name: Fuzzy.prepare(`${pin.preview}`),
            pin: pin
        }))
        if (root.sloppySearch) {
            return root.pins.map(pin => ({
                pin: pin,
                score: Levendist.computeTextMatchScore(`${pin.preview}`.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
                .map(item => item.pin)
        }
        return Fuzzy.go(search, prepared, {
            all: true,
            key: "name"
        }).map(result => result.obj.pin)
    }

    Process {
        id: pinProc
        property var pinData: null
        function begin(entry, data) {
            pinProc.pinData = data
            command = ["bash", "-c", `mkdir -p '${root.pinsDir}' && printf '%s' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode > '${data.file}'`]
            running = true
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && pinProc.pinData) {
                root.pins = root.pins.concat([pinProc.pinData]).slice(-100)
                root.savePins()
            } else {
                console.error("[Cliphist] Failed to pin entry with code", exitCode, "and status", exitStatus)
            }
            pinProc.pinData = null
        }
    }

    FileView {
        id: pinsFileView
        path: Qt.resolvedUrl(root.pinsIndexPath)
        onLoaded: {
            try {
                const parsed = JSON.parse(pinsFileView.text())
                root.pins = Array.isArray(parsed) ? parsed : []
            } catch (e) {
                console.error("[Cliphist] Failed to parse pinned entries:", e)
                root.pins = []
            }
            root.pinsLoaded = true
        }
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                console.error("[Cliphist] Failed to load pinned entries:", error)
            root.pins = []
            root.pinsLoaded = true
        }
    }

    Component.onCompleted: pinsFileView.reload()

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy`]);
        }
    }

    function paste(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`]);
        }
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            return entryIsImage(entry);
        }).slice(0, count)
        const pasteCommands = [...targetEntries].reverse().map(entry => `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`)
        // Act
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function wipe() {
        wipeProc.running = true;
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart()
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh()
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus)
            }
        }
    }

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }
    }
}
