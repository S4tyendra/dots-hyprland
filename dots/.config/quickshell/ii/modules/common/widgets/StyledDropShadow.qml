import QtQuick
import QtQuick.Effects
import qs.modules.common

// GPU shadow. Qt5Compat DropShadow ran a CPU Gaussian blur
// whenever the source layer was dirty (clock, cookies, etc.).
MultiEffect {
    required property var target
    source: target
    anchors.fill: source
    shadowEnabled: true
    shadowBlur: 0.6
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 2
    shadowColor: Appearance.colors.colShadow
    autoPaddingEnabled: true
}
