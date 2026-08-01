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

    function resetState() {
        currentPage = 0
        showingProfile = false
    }

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
            color: "transparent"
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5
            z: 1

            PreBlurredBackground {
                panelX: settingsWindow.x
                panelY: settingsWindow.y
                cornerRadius: settingsWindow.radius
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            property bool userMoved: false
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

                                    active: Config.ready && (root.currentPage === index || item !== null)

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
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen
    }
}
