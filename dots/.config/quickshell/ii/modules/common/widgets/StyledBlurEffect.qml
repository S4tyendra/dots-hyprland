import QtQuick
import QtQuick.Effects

MultiEffect {
    id: root
    source: wallpaper
    anchors.fill: source
    saturation: 0.2
    blurEnabled: true
    blurMax: 32  // was 100; blurMax allocates GPU kernel — 32 is visually sufficient
    blur: 1
}
