import QtQuick
import qs.modules.common
import qs.modules.common.functions as CF

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real panelX: 0
    property real panelY: 0
    property real screenW: Window.window?.screen?.width ?? 1920
    property real screenH: Window.window?.screen?.height ?? 1080
    property color tintColor: Appearance.colors.colLayer0
    property real tintOpacity: 0.65
    property real cornerRadius: 0

    // Blurred wallpaper cropped and positioned to match the screen behind this item
    StyledImage {
        id: blurredImg
        source: Directories.generatedBlurredWallpaperPath
        width: root.screenW
        height: root.screenH
        x: -root.panelX
        y: -root.panelY
        fillMode: Image.PreserveAspectCrop
        cache: true
        smooth: true
    }

    // Color tint overlay
    Rectangle {
        anchors.fill: parent
        color: root.tintColor
        opacity: root.tintOpacity
        radius: root.cornerRadius
    }
}
