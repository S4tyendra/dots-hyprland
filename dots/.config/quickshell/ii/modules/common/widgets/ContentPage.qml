import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    property real baseWidth: 600
    property bool forceWidth: false
    property real pagePadding: 24
    property real bottomContentPadding: 32

    default property alias data: contentColumn.data

    clip: true
    contentWidth: width
    contentHeight: root.pagePadding + contentColumn.implicitHeight + root.bottomContentPadding
    implicitWidth: root.baseWidth + root.pagePadding * 2
    
    ColumnLayout {
        id: contentColumn
        objectName: "settingsContent"
        width: Math.min(root.baseWidth, Math.max(0, root.width - root.pagePadding * 2))
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: root.pagePadding
        }
        spacing: 28
    }

}
