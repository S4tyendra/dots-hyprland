import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

GridLayout {
    id: root
    property string text: ""
    property string icon: ""
    property list<var> options: [
        {
            "displayName": "Option 1",
            "icon": "check",
            "value": 1
        },
        {
            "displayName": "Option 2",
            "icon": "close",
            "value": 2
        },
    ]
    property var currentValue: null

    signal selected(var newValue)

    columns: width < 480 ? 1 : 2
    columnSpacing: 12
    rowSpacing: 8
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        Layout.fillWidth: root.columns === 1
        Layout.preferredWidth: Math.min(160, labelWidget.implicitWidth + (root.icon ? 32 : 0))
        Layout.maximumWidth: root.columns === 1 ? Infinity : 160
        spacing: 10
        visible: root.text !== ""
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

    Item {
        Layout.fillWidth: true
        implicitHeight: buttonsFlow.implicitHeight

        Flow {
            id: buttonsFlow
            objectName: "selectionButtons"
            width: parent.width
            spacing: 2

            Repeater {
                id: optionButtons
                model: root.options
                delegate: SelectionGroupButton {
                    id: paletteButton
                    required property var modelData
                    required property int index
                    onYChanged: {
                        if (index === 0) {
                            paletteButton.leftmost = true;
                        } else {
                            var prev = optionButtons.itemAt(index - 1);
                            var thisIsOnNewLine = prev && prev.y !== paletteButton.y;
                            paletteButton.leftmost = thisIsOnNewLine;
                            if (prev) prev.rightmost = thisIsOnNewLine;
                        }
                    }
                    leftmost: index === 0
                    rightmost: index === root.options.length - 1
                    buttonIcon: modelData.icon || ""
                    buttonText: modelData.displayName
                    toggled: root.currentValue == modelData.value
                    onClicked: {
                        root.selected(modelData.value);
                    }
                }
            }
        }
    }
}
