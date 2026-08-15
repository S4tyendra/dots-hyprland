import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    readonly property bool borderless: Config.options.bar.borderless === "transparent"
    property bool showDate: Config.options.bar.verbose
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    implicitWidth: root.vertical ? 32 : flow.implicitWidth + 4
    implicitHeight: root.vertical ? flow.implicitHeight + 4 : 32

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
        onWheel: (wheel) => {
            const step = (Audio.value || 0) < 0.1 ? 0.01 : 0.02;
            if (wheel.angleDelta.y > 0) {
                Audio.sink.audio.volume = Math.min(1, (Audio.sink?.audio?.volume || 0) + step);
            } else if (wheel.angleDelta.y < 0) {
                Audio.sink.audio.volume = Math.max(0, (Audio.sink?.audio?.volume || 0) - step);
            }
            GlobalStates.osdVolumeOpen = true;
        }

        Flow {
            id: flow
            anchors.centerIn: parent
            flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
            spacing: isMaterial ? 2 : 10

            Revealer {
                reveal: true
                MaterialSymbol {
                    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                }
            }
            Revealer {
                reveal: Audio.source?.audio?.muted ?? false
                MaterialSymbol {
                    text: "mic_off"
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                }
            }
            Loader {
                source: "HyprlandXkbIndicator.qml"
                onLoaded: item.color = root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
            MaterialSymbol {
                text: Network.materialSymbol
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
            MaterialSymbol {
                visible: BluetoothStatus.available
                text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
            Loader {
                id: notifLoader
                active: Notifications.silent || Notifications.unread > 0
                visible: active
                source: "NotificationUnreadCount.qml"
            }
        }
    }
}
