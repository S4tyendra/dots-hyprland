import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdLockKeyIndicator {
    icon: "filter_1"
    name: Translation.tr("Num Lock")
    active: HyprlandXkb.numLock
}
