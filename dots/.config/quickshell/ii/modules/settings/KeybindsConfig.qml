import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    readonly property string mainPath: Directories.config + "/hypr/hyprland/keybinds.lua"
    readonly property string customPath: Directories.config + "/hypr/custom/keybinds.lua"
    readonly property string captureSubmap: "qs_keybind_capture"

    property var entries: []
    property var filtered: []
    property var fileTexts: ({})
    property string query: ""

    property bool capturing: false
    property var editingEntry: null
    property string capturedCombo: ""
    property string captureError: ""

    function parseLua(path, text) {
        const result = []
        if (!text) return result
        const lines = text.split("\n")
        const bindRegex = /^\s*hl\.bind\(\s*"([^"]+)"/
        const descriptionRegex = /description\s*=\s*"([^"]*)"/
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(bindRegex)
            if (!match) continue
            const descriptionMatch = lines[i].match(descriptionRegex)
            result.push({
                path: path,
                line: i,
                combo: match[1],
                description: descriptionMatch ? descriptionMatch[1] : ""
            })
        }
        return result
    }

    function rebuild() {
        let list = []
        list = list.concat(parseLua(mainPath, fileTexts[mainPath] || ""))
        list = list.concat(parseLua(customPath, fileTexts[customPath] || ""))
        entries = list
        applyFilter()
    }

    function applyFilter() {
        const q = query.trim().toLowerCase()
        filtered = q === ""
            ? entries
            : entries.filter(e => (e.combo + " " + e.description).toLowerCase().includes(q))
    }

    onQueryChanged: applyFilter()

    function normalizeCombo(combo) {
        const parts = combo.split("+").map(part => part.trim())
        const key = parts.pop() || ""
        parts.sort()
        return parts.join(" + ") + " + " + key.toUpperCase()
    }

    function isModifierKey(key) {
        return key === Qt.Key_Shift || key === Qt.Key_Control || key === Qt.Key_Alt
            || key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R
            || key === Qt.Key_Hyper_L || key === Qt.Key_Hyper_R || key === Qt.Key_CapsLock
    }

    function keyName(event) {
        const key = event.key
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key)
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key)
        if (key >= Qt.Key_F1 && key <= Qt.Key_F24)
            return "F" + (key - Qt.Key_F1 + 1)

        switch (key) {
        case Qt.Key_Space: return "Space"
        case Qt.Key_Tab: return "Tab"
        case Qt.Key_Return:
        case Qt.Key_Enter: return "Return"
        case Qt.Key_Backspace: return "BackSpace"
        case Qt.Key_Delete: return "Delete"
        case Qt.Key_Insert: return "Insert"
        case Qt.Key_Home: return "Home"
        case Qt.Key_End: return "End"
        case Qt.Key_PageUp: return "Page_Up"
        case Qt.Key_PageDown: return "Page_Down"
        case Qt.Key_Left: return "Left"
        case Qt.Key_Right: return "Right"
        case Qt.Key_Up: return "Up"
        case Qt.Key_Down: return "Down"
        case Qt.Key_Slash: return "Slash"
        case Qt.Key_Question: return "question"
        case Qt.Key_Period: return "Period"
        case Qt.Key_Greater: return "greater"
        case Qt.Key_Comma: return "Comma"
        case Qt.Key_Less: return "less"
        case Qt.Key_Semicolon: return "Semicolon"
        case Qt.Key_Colon: return "colon"
        case Qt.Key_Apostrophe: return "Apostrophe"
        case Qt.Key_QuoteDbl: return "quotedbl"
        case Qt.Key_Backslash: return "Backslash"
        case Qt.Key_Bar: return "bar"
        case Qt.Key_Minus: return "Minus"
        case Qt.Key_Underscore: return "underscore"
        case Qt.Key_Equal: return "Equal"
        case Qt.Key_Plus: return "plus"
        case Qt.Key_BracketLeft: return "BracketLeft"
        case Qt.Key_BraceLeft: return "braceleft"
        case Qt.Key_BracketRight: return "BracketRight"
        case Qt.Key_BraceRight: return "braceright"
        case Qt.Key_QuoteLeft: return "Grave"
        case Qt.Key_AsciiTilde: return "asciitilde"
        case Qt.Key_Exclam: return "exclam"
        case Qt.Key_At: return "at"
        case Qt.Key_NumberSign: return "numbersign"
        case Qt.Key_Dollar: return "dollar"
        case Qt.Key_Percent: return "percent"
        case Qt.Key_AsciiCircum: return "asciicircum"
        case Qt.Key_Ampersand: return "ampersand"
        case Qt.Key_Asterisk: return "asterisk"
        case Qt.Key_ParenLeft: return "parenleft"
        case Qt.Key_ParenRight: return "parenright"
        default: return ""
        }
    }

    function comboFromEvent(event) {
        const mods = []
        if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
        if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
        if (event.modifiers & Qt.AltModifier) mods.push("ALT")
        if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
        const key = keyName(event)
        if (key === "") return ""
        if (mods.length === 0 && !/^F([1-9]|1[0-9]|2[0-4])$/.test(key)) return ""
        return mods.concat([key]).join(" + ")
    }

    function handleKey(event) {
        if (!capturing) return
        event.accepted = true
        if (event.isAutoRepeat) return
        if (event.key === Qt.Key_Escape) {
            closeDialog()
            return
        }
        if (isModifierKey(event.key)) return
        const combo = comboFromEvent(event)
        if (combo === "") {
            captureError = Translation.tr("Unsupported key")
            capturedCombo = ""
            return
        }
        const conflict = entries.find(e => e !== editingEntry && normalizeCombo(e.combo) === normalizeCombo(combo))
        capturedCombo = combo
        captureError = conflict
            ? Translation.tr("Already used by \"%1\"").arg(conflict.description || conflict.combo)
            : ""
    }

    function startEdit(entry) {
        editingEntry = entry
        capturedCombo = ""
        captureError = ""
        capturing = true
        rebindPopup.open()
        submapEnter.running = true
    }

    function closeDialog() {
        capturing = false
        capturePollTimer.stop()
        rebindPopup.close()
        submapReset.running = true
    }

    function applyRebind() {
        if (!editingEntry || capturedCombo === "" || captureError !== "") return
        const path = editingEntry.path
        const text = fileTexts[path] || ""
        const lines = text.split("\n")
        const original = lines[editingEntry.line] || ""
        const updated = original.replace(/^(\s*hl\.bind\(\s*")[^"]+(")/, (match, prefix, suffix) => `${prefix}${capturedCombo}${suffix}`)
        if (updated === original) {
            captureError = Translation.tr("Couldn't find the line to edit")
            return
        }
        lines[editingEntry.line] = updated
        const newText = lines.join("\n")
        const view = path === mainPath ? mainFile : customFile
        fileTexts = Object.assign({}, fileTexts, { [path]: newText })
        view.setText(newText)
        closeDialog()
        reloadTimer.restart()
    }

    function descriptionName(description) {
        if (description === "") return Translation.tr("Custom bind")
        const index = description.indexOf(":")
        return index > 0 ? description.slice(index + 1).trim() : description
    }

    function descriptionCategory(description) {
        const index = description.indexOf(":")
        return index > 0 ? description.slice(0, index).trim() : ""
    }

    function fileName(path) {
        return path === mainPath ? "keybinds.lua" : "custom/keybinds.lua"
    }

    Component.onCompleted: {
        mainFile.reload()
        customFile.reload()
    }

    FileView {
        id: mainFile
        path: Qt.resolvedUrl(page.mainPath)
        blockLoading: true
        onLoaded: {
            page.fileTexts = Object.assign({}, page.fileTexts, { [page.mainPath]: mainFile.text() })
            page.rebuild()
        }
        onLoadFailed: (error) => console.warn("[Keybinds] Failed to load " + page.mainPath + ": " + error)
    }

    FileView {
        id: customFile
        path: Qt.resolvedUrl(page.customPath)
        blockLoading: true
        onLoaded: {
            page.fileTexts = Object.assign({}, page.fileTexts, { [page.customPath]: customFile.text() })
            page.rebuild()
        }
        onLoadFailed: (error) => console.warn("[Keybinds] Failed to load " + page.customPath + ": " + error)
    }

    Process {
        id: submapEnter
        // This config drives Hyprland through its Lua API, so dispatchers use hl.dsp
        command: ["hyprctl", "dispatch", `hl.dsp.submap("${page.captureSubmap}")`]
        onExited: (code) => {
            // Only start checking once the submap is actually active,
            // otherwise the first poll races the compositor and cancels the dialog.
            // If entering failed, keep the dialog open and rely on the local key handler.
            if (page.capturing && code === 0)
                capturePollTimer.restart()
        }
    }

    Process {
        id: submapReset
        command: ["hyprctl", "dispatch", 'hl.dsp.submap("reset")']
    }

    Process {
        id: submapCheck
        command: ["hyprctl", "submap"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (page.capturing && text.trim() !== page.captureSubmap)
                    page.closeDialog()
            }
        }
    }

    Timer {
        id: capturePollTimer
        interval: 400
        repeat: true
        running: false
        onTriggered: {
            if (!submapCheck.running)
                submapCheck.running = true
        }
    }

    Process {
        id: reloadProc
        command: ["hyprctl", "reload"]
    }

    Timer {
        id: reloadTimer
        interval: 300
        repeat: false
        onTriggered: reloadProc.running = true
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Keybinds")

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 6

                    MaterialSymbol {
                        text: "search"
                        iconSize: 18
                        color: Appearance.colors.colSubtext
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        padding: 0
                        background: Item {}
                        placeholderText: Translation.tr("Search keybinds")
                        placeholderTextColor: Appearance.colors.colSubtext
                        color: Appearance.colors.colOnLayer1
                        font {
                            family: Appearance.font.family.main
                            pixelSize: Appearance.font.pixelSize.small
                        }
                        onTextChanged: page.query = text
                    }
                }
            }

            StyledText {
                text: Translation.tr("%1 binds").arg(page.filtered.length)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: Translation.tr("Click a bind to change its shortcut. Changes are written to the Lua config and reloaded immediately.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: page.filtered

            Rectangle {
                id: bindRow
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 52
                radius: Appearance.rounding.small
                color: rowMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.startEdit(bindRow.modelData)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 12

                    Rectangle {
                        implicitWidth: Math.max(64, comboText.implicitWidth + 20)
                        implicitHeight: 28
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: Appearance.colors.colOutline

                        StyledText {
                            id: comboText
                            anchors.centerIn: parent
                            text: bindRow.modelData.combo
                            font {
                                family: Appearance.font.family.monospace
                                pixelSize: Appearance.font.pixelSize.small
                            }
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2

                        StyledText {
                            Layout.fillWidth: true
                            text: page.descriptionName(bindRow.modelData.description)
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                const category = page.descriptionCategory(bindRow.modelData.description)
                                const file = page.fileName(bindRow.modelData.path)
                                return category === "" ? file : `${category} · ${file}`
                            }
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }

                    MaterialSymbol {
                        text: "edit"
                        iconSize: 18
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: page.filtered.length === 0
            text: Translation.tr("No keybinds match your search.")
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colSubtext
        }
    }

    Popup {
        id: rebindPopup
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        width: 380
        padding: 20
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose

        onOpened: captureArea.forceActiveFocus()
        onClosed: {
            if (page.capturing)
                page.closeDialog()
        }

        background: Rectangle {
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }

        contentItem: FocusScope {
            id: captureArea
            implicitHeight: contentColumn.implicitHeight
            focus: true

            Keys.onPressed: (event) => page.handleKey(event)

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                spacing: 10

                StyledText {
                    text: Translation.tr("Change shortcut")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer2
                }

                StyledText {
                    Layout.fillWidth: true
                    text: page.editingEntry
                        ? Translation.tr("\"%1\" is currently %2").arg(page.descriptionName(page.editingEntry.description)).arg(page.editingEntry.combo)
                        : ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    Layout.topMargin: 4
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colPrimary

                    StyledText {
                        anchors.centerIn: parent
                        text: page.capturedCombo !== "" ? page.capturedCombo : Translation.tr("Press a shortcut…")
                        font {
                            family: page.capturedCombo !== "" ? Appearance.font.family.monospace : Appearance.font.family.main
                            pixelSize: page.capturedCombo !== "" ? Appearance.font.pixelSize.large : Appearance.font.pixelSize.normal
                        }
                        color: page.capturedCombo !== "" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: page.captureError !== ""
                    text: page.captureError
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colError
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        buttonText: Translation.tr("Cancel")
                        implicitHeight: 34
                        leftPadding: 14
                        rightPadding: 14
                        onClicked: page.closeDialog()
                    }

                    RippleButton {
                        buttonText: Translation.tr("Apply")
                        implicitHeight: 34
                        leftPadding: 14
                        rightPadding: 14
                        enabled: page.capturedCombo !== "" && page.captureError === ""
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        contentItem: StyledText {
                            text: Translation.tr("Apply")
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnPrimary
                        }
                        onClicked: page.applyRebind()
                    }
                }
            }
        }
    }
}
