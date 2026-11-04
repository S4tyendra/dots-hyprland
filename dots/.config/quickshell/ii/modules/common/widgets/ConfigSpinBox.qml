import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string text: ""
    property string icon
    property alias value: spinBoxWidget.value
    property alias stepSize: spinBoxWidget.stepSize
    property alias from: spinBoxWidget.from
    property alias to: spinBoxWidget.to
    spacing: 10
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 10
        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            wrapMode: Text.Wrap
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
    }

    StyledSpinBox {
        id: spinBoxWidget
        Layout.fillWidth: false
        Layout.preferredWidth: 112
        implicitHeight: 40
        baseHeight: 32
        leftPadding: 32
        rightPadding: 32
        topPadding: 0
        bottomPadding: 0
        value: root.value
    }
}
