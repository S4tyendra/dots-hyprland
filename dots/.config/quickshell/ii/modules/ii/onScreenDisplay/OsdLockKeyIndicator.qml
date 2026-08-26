import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string icon
    required property string name
    required property bool active

    implicitWidth: Appearance.sizes.osdWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: valueIndicator.implicitHeight + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: valueIndicator
    }
    Rectangle {
        id: valueIndicator
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0

        implicitWidth: valueRow.implicitWidth
        implicitHeight: valueRow.implicitHeight + 18

        RowLayout {
            id: valueRow
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 18
            spacing: 12

            Item {
                implicitWidth: 30
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    anchors.centerIn: parent
                    color: root.active ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                    renderType: Text.QtRendering
                    text: root.icon
                    iconSize: 24
                    fill: root.active ? 1 : 0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: root.name
                }

                StyledText {
                    color: root.active ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    text: root.active ? Translation.tr("On") : Translation.tr("Off")
                }
            }
        }
    }
}
