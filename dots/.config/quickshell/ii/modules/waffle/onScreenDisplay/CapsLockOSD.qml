import QtQuick
import qs.services
import qs.modules.waffle.looks

OSDValue {
    id: root
    iconName: "keyboard"
    value: HyprlandXkb.capsLock ? 1 : 0
    showNumber: false

    Connections {
        target: HyprlandXkb
        function onCapsLockChanged() {
            root.timer.restart();
        }
    }
}
