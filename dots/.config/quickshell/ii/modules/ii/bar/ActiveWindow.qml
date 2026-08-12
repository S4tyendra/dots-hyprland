import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root
    property bool vertical: false
    property bool isMirrored: false
    readonly property var monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property string activeWindowAddress: activeWindow?.HyprlandToplevel?.address ? `0x${activeWindow.HyprlandToplevel.address}` : ""
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id ?? 1)

    property string activeAppClass: {
        if (!root.focusingThisMonitor || !root.activeWindow?.activated)
            return root.biggestWindow?.class ?? ""
        return root.activeWindow?.appId ?? root.biggestWindow?.class ?? ""
    }

    property var mainAppIconSource: {
        if (!root.activeAppClass || root.activeAppClass === "")
            return Quickshell.iconPath("user-desktop", "image-missing")
        return Quickshell.iconPath(AppSearch.guessIcon(root.activeAppClass),
            Quickshell.iconPath("user-desktop", "image-missing"))
    }

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : Math.min(colLayout.implicitWidth + 6, 280)
    implicitHeight: vertical ? iconItem.implicitHeight : Appearance.sizes.barHeight

    // Vertical
    Item {
        id: iconItem
        visible: root.vertical
        anchors.centerIn: parent
        implicitWidth: 22
        implicitHeight: 22

        IconImage {
            anchors.centerIn: parent
            source: root.mainAppIconSource
            implicitSize: 18
            visible: root.mainAppIconSource !== ""
        }
    }

    // Horizontal
    ColumnLayout {
        id: colLayout
        visible: !root.vertical
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 3
        spacing: -4
        layoutDirection: root.isMirrored ? Qt.RightToLeft : Qt.LeftToRight

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.appId :
                (root.biggestWindow?.class) ?? Translation.tr("Desktop")
        }
        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id ?? 1}`
        }
    }
}
