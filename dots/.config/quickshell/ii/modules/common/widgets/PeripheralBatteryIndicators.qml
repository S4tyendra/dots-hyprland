import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

GridLayout {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnLayer1
    property var readings: PeripheralBattery.indicators
    columns: vertical ? 1 : Math.max(1, readings.length)
    columnSpacing: 8
    rowSpacing: 4
    visible: readings.length > 0

    Repeater {
        model: root.readings
        GridLayout {
            id: reading
            required property var modelData
            readonly property color textColor: !modelData.charging && modelData.percentage * 100 <= Config.options.battery.peripheralLow
                ? Appearance.colors.colError : root.color
            columns: root.vertical ? 1 : 2
            columnSpacing: 2
            rowSpacing: 0
            Accessible.role: Accessible.StaticText
            Accessible.name: modelData.name + ": " + Math.round(modelData.percentage * 100) + "%"
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: reading.modelData.charging ? "battery_charging_full" : reading.modelData.icon
                iconSize: Appearance.font.pixelSize.normal
                color: reading.textColor
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(reading.modelData.percentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: reading.textColor
            }
            HoverHandler { id: hover }
            StyledToolTip {
                extraVisibleCondition: false
                alternativeVisibleCondition: hover.hovered
                text: reading.modelData.name + ": " + Math.round(reading.modelData.percentage * 100) + "%"
            }
        }
    }
}
