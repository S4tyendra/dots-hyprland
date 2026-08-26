import QtQuick
import qs.services
import qs.modules.waffle.looks

OSDValue {
    id: root
    iconName: "dialpad"
    value: HyprlandXkb.numLock ? 1 : 0
    showNumber: false

    Connections {
        target: HyprlandXkb
        function onNumLockChanged() {
            root.timer.restart();
        }
    }
}
