import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdLockKeyIndicator {
    icon: "keyboard_capslock"
    name: Translation.tr("Caps Lock")
    active: HyprlandXkb.capsLock
}
