//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Scope {
    id: root
    property real contentPadding: 8
    property bool showingProfile: false
    property var pages: [
        { name: Translation.tr("Quick"),      icon: "instant_mix",    component: Qt.resolvedUrl("../../settings/QuickConfig.qml") },
        { name: Translation.tr("General"),    icon: "browse",         component: Qt.resolvedUrl("../../settings/GeneralConfig.qml") },
        { name: Translation.tr("Bar"),        icon: "toast",          iconRotation: 180, component: Qt.resolvedUrl("../../settings/BarConfig.qml") },
        { name: Translation.tr("Background"), icon: "texture",        component: Qt.resolvedUrl("../../settings/BackgroundConfig.qml") },
        { name: Translation.tr("Interface"),  icon: "bottom_app_bar", component: Qt.resolvedUrl("../../settings/InterfaceConfig.qml") },
        { name: Translation.tr("Services"),   icon: "settings",       component: Qt.resolvedUrl("../../settings/ServicesConfig.qml") },
        { name: Translation.tr("Advanced"),   icon: "construction",   component: Qt.resolvedUrl("../../settings/AdvancedConfig.qml") },
        { name: Translation.tr("About"),      icon: "info",           component: Qt.resolvedUrl("../../settings/About.qml") }
    ]
    property int currentPage: 0
    // Bit mask of pages that were opened and should stay loaded
    property int visitedMask: 0
    // True while every page is loaded temporarily to build the search index
    property bool indexing: false
    property string pendingSection: ""

    function resetState() {
        currentPage = 0
        showingProfile = false
        pendingSection = ""
        clearSearch()
    }

    function updateSearch(text) {
        SettingsSearch.query = text
        indexing = text.trim() !== ""
    }

    function clearSearch() {
        settingsSearchField.text = ""
        SettingsSearch.query = ""
        indexing = false
        pendingSection = ""
    }

    function navigateToSearchResult(result) {
        visitedMask = visitedMask | (1 << result.pageIndex)
        currentPage = result.pageIndex
        showingProfile = false
        clearSearch()
        pendingSection = result.section
        scrollAttempts = 0
        scrollTimer.restart()
    }

    // Focus the search field once the panel is actually visible
    function focusSearch() {
        searchFocusAttempts = 0
        searchFocusTimer.restart()
    }

    property int searchFocusAttempts: 0

    Timer {
        id: searchFocusTimer
        interval: 80
        repeat: true
        onTriggered: {
            searchFocusAttempts++
            if (panelWindow.visible && searchFocusAttempts > 1) {
                stop()
                settingsSearchField.forceActiveFocus()
            } else if (searchFocusAttempts > 20) {
                stop()
            }
        }
    }

    function scrollToPendingSection() {
        if (pendingSection === "")
            return
        const loader = pagesRepeater.itemAt(currentPage)
        if (!loader || !loader.item)
            return
        const section = findSectionByTitle(loader.item, pendingSection)
        if (!section)
            return
        pendingSection = ""
        loader.item.contentY = Math.max(0, section.y - 12)
    }

    function findSectionByTitle(item, title) {
        if (!item)
            return null
        if (item.title === title && item.children !== undefined)
            return item
        const children = item.children
        if (!children)
            return null
        for (let i = 0; i < children.length; i++) {
            const found = findSectionByTitle(children[i], title)
            if (found)
                return found
        }
        return null
    }

    property int scrollAttempts: 0

    Timer {
        id: scrollTimer
        interval: 120
        repeat: true
        onTriggered: {
            root.scrollAttempts++
            root.scrollToPendingSection()
            if (root.pendingSection === "" || root.scrollAttempts > 20) {
                stop()
                root.scrollAttempts = 0
            }
        }
    }

    onCurrentPageChanged: visitedMask = visitedMask | (1 << currentPage)

    Connections {
        target: GlobalStates
        function onSettingsOpenChanged() {
            if (GlobalStates.settingsOpen) {
                Config.readWriteDelay = 0
                root.resetState()
            }
        }
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen

        function hide() {
            GlobalStates.settingsOpen = false
        }

        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow)
                settingsWindow.userMoved = false
                // Take focus so Esc / Ctrl+F work without clicking first
                Qt.callLater(() => settingsWindow.forceActiveFocus())
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: GlobalStates.settingsOpen ? 1 : 0
            z: 0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: settingsWindow
            width: Math.min(parent.width - 80, 980)
            height: Math.min(parent.height - 80, 665)
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5
            z: 1

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            property bool userMoved: false
            focus: true
            anchors.centerIn: userMoved ? undefined : parent

            opacity: GlobalStates.settingsOpen ? 1 : 0
            scale: GlobalStates.settingsOpen ? 1 : 0.95

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide()
                } else if (event.key === Qt.Key_F && event.modifiers === Qt.ControlModifier) {
                    settingsSearchField.forceActiveFocus()
                    event.accepted = true
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: contentPadding
                }
                spacing: 0

                // Top bar — visual differentiation, title + close
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8

                        Item { Layout.preferredWidth: 12 }

                        StyledText {
                            text: Translation.tr("Settings")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }

                        // Search across all settings pages
                        Rectangle {
                            Layout.preferredWidth: 340
                            Layout.preferredHeight: 32
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colLayer1
                            border.width: settingsSearchField.activeFocus ? 1 : 0
                            border.color: Appearance.colors.colPrimary

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 4
                                spacing: 6

                                MaterialSymbol {
                                    text: "search"
                                    iconSize: 18
                                    color: Appearance.colors.colSubtext
                                }

                                TextField {
                                    id: settingsSearchField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    padding: 0
                                    leftPadding: 0
                                    rightPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    placeholderText: Translation.tr("Search settings (Ctrl+F)")
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    color: Appearance.colors.colOnLayer1
                                    selectionColor: Appearance.colors.colSecondaryContainer
                                    selectedTextColor: Appearance.colors.colOnSecondaryContainer
                                    font {
                                        family: Appearance.font.family.main
                                        pixelSize: Appearance.font.pixelSize.small
                                    }
                                    background: Item {}
                                    onTextChanged: root.updateSearch(text)
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Down) {
                                            if (searchResultsList.count > 0) {
                                                searchResultsList.currentIndex = 0
                                                searchResultsList.forceActiveFocus()
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (searchResultsList.count > 0)
                                                root.navigateToSearchResult(SettingsSearch.results[0])
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Escape) {
                                            if (text !== "") {
                                                root.clearSearch()
                                            } else {
                                                panelWindow.hide()
                                            }
                                            event.accepted = true
                                        }
                                    }
                                }

                                RippleButton {
                                    visible: settingsSearchField.text !== ""
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    buttonRadius: Appearance.rounding.full
                                    onClicked: root.clearSearch()
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 16
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }
                        }

                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            implicitWidth: 32
                            implicitHeight: 32
                            onClicked: panelWindow.hide()
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1
                        color: Appearance.colors.colLayer0Border
                        opacity: 0.5
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: contentPadding

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.margins: 0
                        implicitWidth: 195
                        color: Appearance.m3colors.m3surfaceContainerLow
                        radius: Appearance.rounding.normal

                        NavigationRail {
                            id: navRail
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                                leftMargin: 20
                            }
                            spacing: 10

                            Item {
                                id: profileHeader
                                implicitWidth: 150
                                implicitHeight: 52
                                Layout.topMargin: 15
                                Layout.bottomMargin: 5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 12

                                    Rectangle {
                                        id: avatarRect
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 19
                                        color: Appearance.colors.colPrimaryContainer
                                        clip: true

                                        Image {
                                            id: avatarImage
                                            anchors.fill: parent
                                            source: (Config.options?.profile?.avatarPicture ?? "") !== ""
                                                ? "file://" + Config.options.profile.avatarPicture
                                                : ""
                                            sourceSize.width: avatarImage.width * 2
                                            sourceSize.height: avatarImage.height * 2
                                            fillMode: Image.PreserveAspectCrop
                                            visible: (Config.options?.profile?.avatarPicture ?? "") !== ""
                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: Item {
                                                    width: avatarImage.width
                                                    height: avatarImage.height
                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: avatarRect.radius
                                                    }
                                                }
                                            }
                                            onStatusChanged: {
                                                if (status === Image.Error)
                                                    visible = false
                                            }
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "account_circle"
                                            iconSize: 24
                                            color: Appearance.colors.colOnPrimaryContainer
                                            visible: avatarImage.status === Image.Error || (Config.options?.profile?.avatarPicture ?? "") === ""
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 0
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter

                                        StyledText {
                                            text: (Config.options?.profile?.displayName ?? "") === "" ? (Quickshell.env("USER") || "User") : Config.options.profile.displayName
                                            font.bold: true
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            color: Appearance.colors.colOnLayer0
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        StyledText {
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                            opacity: 0.7
                                            Layout.fillWidth: true
                                            text: (Config.options?.profile?.descriptionText ?? "") === "::uptime::"
                                                ? Translation.tr("Up %1").arg(DateTime.uptime)
                                                : (SystemInfo.distroName || "Linux")
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showingProfile = !root.showingProfile
                                }
                            }

                            Rectangle {
                                width: 160
                                Layout.topMargin: -5
                                height: 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.2; color: Appearance.colors.colOutline }
                                    GradientStop { position: 0.8; color: Appearance.colors.colOutline }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                                opacity: 0.15
                            }

                            FloatingActionButton {
                                id: fab
                                Layout.bottomMargin: -25
                                property bool justCopied: false
                                iconText: justCopied ? "check" : "edit"
                                buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
                                expanded: navRail.expanded
                                downAction: () => {
                                    Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`)
                                }
                                altAction: () => {
                                    Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`)
                                    fab.justCopied = true
                                    revertTextTimer.restart()
                                }

                                Timer {
                                    id: revertTextTimer
                                    interval: 1500
                                    onTriggered: { fab.justCopied = false }
                                }

                                StyledToolTip {
                                    text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                                }
                            }

                            NavigationRailTabArray {
                                currentIndex: root.currentPage
                                expanded: navRail.expanded
                                colToggled: root.showingProfile ? "transparent" : Appearance.colors.colSecondaryContainer
                                Repeater {
                                    model: root.pages
                                    NavigationRailButton {
                                        required property var index
                                        required property var modelData
                                        toggled: root.currentPage === index && !root.showingProfile
                                        onPressed: {
                                            root.currentPage = index
                                            root.showingProfile = false
                                        }
                                        expanded: navRail.expanded
                                        buttonIcon: modelData.icon
                                        buttonIconRotation: modelData.iconRotation || 0
                                        buttonText: modelData.name
                                        showToggledHighlight: false
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut

                        Item {
                            anchors.fill: parent

                            Repeater {
                                id: pagesRepeater
                                model: root.pages
                                Loader {
                                    required property var modelData
                                    required property var index
                                    source: modelData.component

                                    // Pages are loaded on first visit, or temporarily while
                                    // indexing for search. Unvisited pages are unloaded again
                                    // once the search is cleared.
                                    active: Config.ready && (root.currentPage === index || (root.visitedMask & (1 << index)) !== 0 || root.indexing)
                                    asynchronous: true

                                    onLoaded: {
                                        if (item)
                                            SettingsSearch.indexPage(index, modelData.name, modelData.icon, item)
                                    }

                                    anchors.fill: parent

                                    property bool isActive: root.currentPage === index && !root.showingProfile
                                    opacity: isActive ? 1 : 0
                                    enabled: isActive
                                    visible: isActive
                                    anchors.topMargin: isActive ? 0 : 12

                                    Behavior on opacity {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on anchors.topMargin {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            Loader {
                                id: profileLoader
                                active: Config.ready
                                anchors.fill: parent
                                source: Qt.resolvedUrl("../../settings/Profile.qml")

                                property bool isActive: root.showingProfile
                                opacity: isActive ? 1 : 0
                                enabled: isActive
                                visible: isActive
                                anchors.topMargin: isActive ? 0 : 12

                                Behavior on opacity {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                                Behavior on anchors.topMargin {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                            }

                            // Search results, shown above the page stack
                            Rectangle {
                                anchors.fill: parent
                                z: 5
                                visible: SettingsSearch.query.trim() !== ""
                                radius: Appearance.rounding.normal
                                color: Appearance.colors.colLayer0

                                ColumnLayout {
                                    anchors {
                                        fill: parent
                                        margins: 12
                                    }
                                    spacing: 6

                                    StyledText {
                                        Layout.leftMargin: 8
                                        text: SettingsSearch.results.length === 0
                                            ? Translation.tr("No settings found for \"%1\"").arg(SettingsSearch.query)
                                            : Translation.tr("%1 settings found").arg(SettingsSearch.results.length)
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                    }

                                    ListView {
                                        id: searchResultsList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        spacing: 2
                                        model: SettingsSearch.results
                                        keyNavigationWraps: true

                                        Keys.onPressed: (event) => {
                                            if (event.key === Qt.Key_Escape) {
                                                root.clearSearch()
                                                settingsSearchField.forceActiveFocus()
                                                event.accepted = true
                                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                if (currentItem)
                                                    root.navigateToSearchResult(SettingsSearch.results[currentIndex])
                                                event.accepted = true
                                            }
                                        }

                                        delegate: RippleButton {
                                            id: searchResultButton
                                            required property var modelData
                                            required property int index
                                            width: searchResultsList.width
                                            implicitHeight: 54
                                            buttonRadius: Appearance.rounding.small
                                            colBackground: CF.ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                                            colBackgroundHover: Appearance.colors.colLayer1Hover
                                            onClicked: root.navigateToSearchResult(modelData)

                                            contentItem: RowLayout {
                                                anchors {
                                                    fill: parent
                                                    leftMargin: 10
                                                    rightMargin: 10
                                                }
                                                spacing: 12

                                                MaterialSymbol {
                                                    text: searchResultButton.modelData.sectionIcon !== ""
                                                        ? searchResultButton.modelData.sectionIcon
                                                        : searchResultButton.modelData.pageIcon
                                                    iconSize: 22
                                                    color: Appearance.colors.colPrimary
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: -1

                                                    StyledText {
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                        text: searchResultButton.modelData.label
                                                        font.pixelSize: Appearance.font.pixelSize.normal
                                                        color: Appearance.colors.colOnLayer1
                                                    }

                                                    StyledText {
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                        text: searchResultButton.modelData.section !== ""
                                                            ? `${searchResultButton.modelData.pageName} · ${searchResultButton.modelData.section}`
                                                            : searchResultButton.modelData.pageName
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.colors.colSubtext
                                                    }
                                                }

                                                MaterialSymbol {
                                                    text: "chevron_right"
                                                    iconSize: 18
                                                    color: Appearance.colors.colSubtext
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            GlobalStates.settingsOpen = !GlobalStates.settingsOpen
        }
        function open(): void {
            GlobalStates.settingsOpen = true
        }
        function close(): void {
            GlobalStates.settingsOpen = false
        }
        function search(): void {
            GlobalStates.settingsOpen = true
            root.focusSearch()
        }
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen
    }

    GlobalShortcut {
        name: "settingsSearch"
        description: "Opens settings with search focused"
        onPressed: {
            GlobalStates.settingsOpen = true
            root.focusSearch()
        }
    }
}
