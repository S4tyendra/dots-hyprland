pragma ComponentBehavior: Bound

import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    // searchingText driven externally via Synchronizer in Overview.qml
    property string searchingText: ""
    property bool showResults: searchingText !== ""
    readonly property int typingResultLimit: 20

    signal requestClose()

    function focusFirstItem() {
        if (resultList.count > 0)
            resultList.currentIndex = 0;
    }

    function focusSearchInput() {
        searchInput.forceActiveFocus();
    }

    function cancelSearch() {
        LauncherSearch.query = "";
        resultList.currentIndex = -1;
    }

    function setSearchingText(text) {
        LauncherSearch.query = text;
        searchInput.text = text;
        searchInput.cursorPosition = text.length;
        focusFirstItem();
    }

    // Sync searchInput when changed externally (clipboard toggle etc.)
    onSearchingTextChanged: {
        if (searchInput.text !== searchingText) {
            searchInput.text = searchingText;
            searchInput.cursorPosition = searchingText.length;
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.forceActiveFocus();
        }
    }

    // Dynamic icon for current search prefix
    readonly property string currentPrefixIcon: {
        const t = root.searchingText;
        if (t.startsWith(Config.options.search.prefix.webSearch))    return "travel_explore";
        if (t.startsWith(Config.options.search.prefix.shellCommand))  return "terminal";
        if (t.startsWith(Config.options.search.prefix.math))          return "calculate";
        if (t.startsWith(Config.options.search.prefix.clipboard))     return "content_paste_search";
        if (t.startsWith(Config.options.search.prefix.emojis))        return "add_reaction";
        if (t.startsWith(Config.options.search.prefix.action))        return "settings_suggest";
        if (t.startsWith(Config.options.search.prefix.app))           return "apps";
        return "search";
    }

    // ─── Compositor-blurred fullscreen scrim ─────────────────────────────────
    // Hyprland handles real-time blur (layer rule: blur = true for quickshell:overview)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: ColorUtils.transparentize(Appearance.m3colors.m3background, 0.55)

        opacity: root.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    // ─── Dismiss on click outside card ───────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    // ─── Glassmorphic search card ─────────────────────────────────────────────
    Rectangle {
        id: cardContainer
        anchors.centerIn: parent
        width: Math.min(720, root.width - 48)
        clip: true
        radius: 22

        // Smooth pop-in animation on open
        opacity: root.visible ? 1 : 0
        scale:   root.visible ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }

        // Height driven by content with smooth expand/collapse on typing
        implicitHeight: columnLayout.implicitHeight
        height: Math.min(implicitHeight, root.height - 80)
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Borderless glass fill
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 0.15)

        // Prevent clicks inside card from closing overlay
        MouseArea { anchors.fill: parent }

        // ─── Content ─────────────────────────────────────────────────────────
        ColumnLayout {
            id: columnLayout
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 10

            // ── Search Header ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 18
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 14

                // Animated category icon badge
                Rectangle {
                    width: 44
                    height: 44
                    radius: 14
                    color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.55)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.currentPrefixIcon
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colPrimary
                    }
                }

                // Search input
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search apps, run commands, math, emojis…")
                    placeholderTextColor: ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.5)
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.m3colors.m3onSurface
                    background: null
                    selectByMouse: true
                    focus: root.visible

                    onTextChanged: {
                        if (LauncherSearch.query !== text)
                            LauncherSearch.query = text;
                    }

                    Keys.onPressed: event => {
                        switch (event.key) {
                            case Qt.Key_Escape:
                                root.requestClose();
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                            case Qt.Key_J:
                                if (event.key === Qt.Key_J && !(event.modifiers & Qt.ControlModifier)) break;
                                if (resultList.count > 0)
                                    resultList.currentIndex = (resultList.currentIndex + 1) % resultList.count;
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                            case Qt.Key_K:
                                if (event.key === Qt.Key_K && !(event.modifiers & Qt.ControlModifier)) break;
                                if (resultList.count > 0)
                                    resultList.currentIndex = (resultList.currentIndex - 1 + resultList.count) % resultList.count;
                                event.accepted = true;
                                break;
                            case Qt.Key_PageDown:
                                if (resultList.count > 0)
                                    resultList.currentIndex = Math.min(resultList.count - 1, resultList.currentIndex + 5);
                                event.accepted = true;
                                break;
                            case Qt.Key_PageUp:
                                if (resultList.count > 0)
                                    resultList.currentIndex = Math.max(0, resultList.currentIndex - 5);
                                event.accepted = true;
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                if (resultList.currentItem) resultList.currentItem.clicked();
                                event.accepted = true;
                                break;
                            case Qt.Key_Tab:
                                if (resultList.currentItem) {
                                    const name = resultList.currentItem.itemName;
                                    if (name) {
                                        searchInput.text = name;
                                        LauncherSearch.query = name;
                                        searchInput.cursorPosition = name.length;
                                    }
                                }
                                event.accepted = true;
                                break;
                        }
                    }
                }

                // Result count pill
                Rectangle {
                    visible: root.showResults
                    height: 26
                    implicitWidth: countLabel.implicitWidth + 18
                    radius: 13
                    color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.6)

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: resultList.count + " " + Translation.tr("results")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                    }
                }
            }

            // ── Quick Tag Filter chips ─────────────────────────────────────
            Item {
                id: tagBar
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                implicitHeight: tagFlow.implicitHeight

                readonly property var tags: [
                    { label: Translation.tr("All"),       prefix: ""  },
                    { label: Translation.tr("Apps"),      prefix: Config.options.search.prefix.app },
                    { label: Translation.tr("Actions"),   prefix: Config.options.search.prefix.action },
                    { label: Translation.tr("Clipboard"), prefix: Config.options.search.prefix.clipboard },
                    { label: Translation.tr("Emojis"),    prefix: Config.options.search.prefix.emojis },
                    { label: Translation.tr("Math"),      prefix: Config.options.search.prefix.math },
                    { label: Translation.tr("Shell"),     prefix: Config.options.search.prefix.shellCommand },
                    { label: Translation.tr("Web"),       prefix: Config.options.search.prefix.webSearch }
                ]

                readonly property var allPrefixes: [
                    Config.options.search.prefix.app,
                    Config.options.search.prefix.action,
                    Config.options.search.prefix.clipboard,
                    Config.options.search.prefix.emojis,
                    Config.options.search.prefix.math,
                    Config.options.search.prefix.shellCommand,
                    Config.options.search.prefix.webSearch
                ]

                Flow {
                    id: tagFlow
                    anchors { left: parent.left; right: parent.right }
                    spacing: 6

                    Repeater {
                        model: tagBar.tags
                        delegate: Rectangle {
                            id: tagChip
                            required property var modelData

                            readonly property bool isActive: {
                                const p = modelData.prefix;
                                if (p === "")
                                    return !tagBar.allPrefixes.some(pfx => pfx !== "" && root.searchingText.startsWith(pfx));
                                return root.searchingText.startsWith(p);
                            }

                            height: 26
                            implicitWidth: chipLabel.implicitWidth + 20
                            radius: 13
                            color: isActive
                                ? Appearance.colors.colPrimary
                                : ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.5)

                            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: tagChip.modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: tagChip.isActive ? Font.Bold : Font.Normal
                                color: tagChip.isActive
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.m3colors.m3onSurfaceVariant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = tagChip.modelData.prefix;
                                    if (p === "") {
                                        LauncherSearch.query = StringUtils.cleanOnePrefix(
                                            root.searchingText, tagBar.allPrefixes);
                                    } else {
                                        LauncherSearch.ensurePrefix(p);
                                    }
                                    searchInput.text = LauncherSearch.query;
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            // ── Separator (only when results visible) ──────────────────────
            Rectangle {
                visible: root.showResults
                Layout.fillWidth: true
                height: 1
                color: ColorUtils.transparentize(Appearance.m3colors.m3outlineVariant, 0.35)
            }

            // ── Results list ───────────────────────────────────────────────
            ListView {
                id: resultList
                visible: root.showResults
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: Math.min(440, contentHeight + 8)
                clip: true
                spacing: 2
                currentIndex: -1
                highlightMoveDuration: 110

                highlight: Rectangle {
                    radius: Appearance.rounding.normal
                    color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.5)
                    Behavior on y      { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                }
                highlightFollowsCurrentItem: true

                Connections {
                    target: LauncherSearch
                    function onResultsChanged() {
                        resultModel.values = LauncherSearch.results.slice(0, root.typingResultLimit);
                        resultList.currentIndex = resultModel.values.length > 0 ? 0 : -1;
                    }
                }

                model: ScriptModel {
                    id: resultModel
                    objectProp: "key"
                }

                delegate: SearchItem {
                    required property var modelData
                    required property int index

                    width: resultList.width
                    entry: modelData
                    query: StringUtils.cleanOnePrefix(root.searchingText, [
                        Config.options.search.prefix.action,
                        Config.options.search.prefix.app,
                        Config.options.search.prefix.clipboard,
                        Config.options.search.prefix.emojis,
                        Config.options.search.prefix.math,
                        Config.options.search.prefix.shellCommand,
                        Config.options.search.prefix.webSearch
                    ])
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }

            // ── Footer keyboard hints ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerLowest, 0.4)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 18

                    Repeater {
                        model: [
                            { key: "↑↓",  hint: Translation.tr("Navigate") },
                            { key: "↵",   hint: Translation.tr("Open") },
                            { key: "Tab", hint: Translation.tr("Autocomplete") },
                            { key: "Esc", hint: Translation.tr("Close") }
                        ]
                        delegate: Row {
                            required property var modelData
                            spacing: 5

                            Rectangle {
                                width: Math.max(22, keyLabel.implicitWidth + 10)
                                height: 18
                                radius: 4
                                color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.7)

                                Text {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    text: parent.parent.modelData.key
                                    font.pixelSize: 10
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.hint
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.m3colors.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; height: 4 }
        }
    }
}
