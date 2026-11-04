import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    default property list<Item> items
    property real bigRadius: Appearance.rounding.normal
    property real smallRadius: Appearance.rounding.unsharpenmore
    property color bgcolor: Appearance.colors.colLayer1
    property real itemVerticalPadding: 24
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight
    readonly property var visibleIndices: {
        const indices = [];
        for (let i = 0; i < root.items.length; i++) {
            if (root.rowVisible(root.items[i])) indices.push(i);
        }
        return indices;
    }

    function rowVisible(item) {
        // Keep cached page geometry stable while its loader is hidden.
        return item && (!root.visible || item.visible) && (!(item instanceof Repeater) || item.count > 0);
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.items.length
            delegate: Rectangle {
                required property int index
                readonly property bool rowVisible: root.rowVisible(root.items[index])
                readonly property bool isFirst: index === root.visibleIndices[0]
                readonly property bool isLast: index === root.visibleIndices[root.visibleIndices.length - 1]
                Layout.fillWidth: true
                Layout.minimumHeight: 0
                Layout.maximumHeight: rowVisible ? Infinity : 0
                Layout.topMargin: rowVisible && !isFirst ? 2 : 0
                implicitHeight: rowVisible ? contentArea.implicitHeight + root.itemVerticalPadding : 0
                clip: !rowVisible
                color: root.bgcolor
                topLeftRadius:     isFirst ? root.bigRadius : root.smallRadius
                topRightRadius:    isFirst ? root.bigRadius : root.smallRadius
                bottomLeftRadius:  isLast  ? root.bigRadius : root.smallRadius
                bottomRightRadius: isLast  ? root.bigRadius : root.smallRadius

                Component.onCompleted: {
                    const child = root.items[index]
                    if (child) {
                        child.parent = contentArea
                        child.Layout.fillWidth = true
                    }
                }

                ColumnLayout {
                    id: contentArea
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                        topMargin: root.itemVerticalPadding / 2
                        bottomMargin: root.itemVerticalPadding / 2
                    }
                    spacing: 0
                }
            }
        }
    }
}
