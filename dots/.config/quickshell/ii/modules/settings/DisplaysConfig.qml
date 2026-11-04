import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    Component.onCompleted: DisplayConfig.refresh()

    ContentSection {
        icon: "desktop_windows"
        title: Translation.tr("Displays")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr(
                      "Choose a mode, rotation or position, then press Apply changes to test it. Changes revert after 15 seconds unless you keep them.")
            wrapMode: Text.Wrap
        }

        RowLayout {
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh")
                enabled: !DisplayConfig.busy
                onClicked: DisplayConfig.refresh()
            }
            RippleButtonWithIcon {
                materialIcon: "check"
                mainText: Translation.tr("Apply changes")
                enabled: !DisplayConfig.busy && DisplayConfig.dirty
                onClicked: DisplayConfig.preview()
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: DisplayConfig.error !== "" || DisplayConfig.dirty
            text: DisplayConfig.error || Translation.tr("You have unapplied changes.")
            color: DisplayConfig.error ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
        RowLayout {
            visible: DisplayConfig.previewing
            StyledText {
                text: Translation.tr("Reverting in %1s").arg(DisplayConfig.secondsLeft)
            }
            RippleButtonWithIcon {
                materialIcon: "check"
                mainText: Translation.tr("Keep")
                onClicked: DisplayConfig.finish(true)
            }
            RippleButtonWithIcon {
                materialIcon: "undo"
                mainText: Translation.tr("Revert")
                onClicked: DisplayConfig.finish(false)
            }
        }

        Rectangle {
            id: canvas
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.small
            clip: true
            readonly property var bounds: {
                const ms = DisplayConfig.monitors;
                const left = Math.min(0, ...ms.map(m => m.x));
                const top = Math.min(0, ...ms.map(m => m.y));
                const right = Math.max(1, ...ms.map(m => m.x + page.logicalSize(m).width));
                const bottom = Math.max(1, ...ms.map(m => m.y + page.logicalSize(m).height));
                return {
                    x: left,
                    y: top,
                    width: right - left,
                    height: bottom - top
                };
            }
            readonly property real factor: Math.min((width - 32) / bounds.width, (height - 32)
                                                    / bounds.height)

            Repeater {
                model: DisplayConfig.monitors
                Rectangle {
                    id: monitorRect
                    required property var modelData
                    required property int index
                    x: 16 + (modelData.x - canvas.bounds.x) * canvas.factor
                    y: 16 + (modelData.y - canvas.bounds.y) * canvas.factor
                    width: page.logicalSize(modelData).width * canvas.factor
                    height: page.logicalSize(modelData).height * canvas.factor
                    color: Appearance.colors.colSecondaryContainer
                    radius: 6
                    border.width: dragArea.pressed ? 2 : 1
                    border.color: Appearance.colors.colPrimary
                    StyledText {
                        anchors.centerIn: parent
                        text: monitorRect.modelData.name
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        enabled: !DisplayConfig.busy
                        drag.target: monitorRect
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        property point start
                        property int startX
                        property int startY
                        property real factor
                        onPressed: mouse => {
                            start = mapToItem(canvas, mouse.x, mouse.y);
                            startX = monitorRect.modelData.x;
                            startY = monitorRect.modelData.y;
                            factor = canvas.factor;
                        }
                        onReleased: mouse => {
                            const end = mapToItem(canvas, mouse.x, mouse.y);
                            DisplayConfig.update(monitorRect.index, "x", Math.round((startX + (end.x - start.x)
                                                                                     / factor) / 10) * 10);
                            DisplayConfig.update(monitorRect.index, "y", Math.round((startY + (end.y - start.y)
                                                                                     / factor) / 10) * 10);
                        }
                    }
                }
            }
        }

        Repeater {
            model: DisplayConfig.monitors
            ColumnLayout {
                id: displayRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                enabled: !DisplayConfig.busy
                StyledText {
                    text: displayRow.modelData.name
                    font.bold: true
                }
                GroupedList {
                    ConfigComboBox {
                        text: Translation.tr("Resolution and refresh rate")
                        currentValue: displayRow.modelData.mode
                        model: [...new Set([displayRow.modelData.mode, ...displayRow.modelData.modes])].map(mode
                                                                                                            => ({
                                                                                                                displayName:
                                                                                                                mode,
                                                                                                                value: mode
                                                                                                            }))
                        onSelected: value => DisplayConfig.update(displayRow.index, "mode", value)
                    }
                    ConfigSpinBox {
                        text: Translation.tr("Scale (%)")
                        value: Math.round(displayRow.modelData.scale * 100)
                        from: 50
                        to: 400
                        stepSize: 25
                        onValueChanged: if (value !== Math.round(displayRow.modelData.scale * 100))
                                            DisplayConfig.update(displayRow.index, "scale", value / 100)
                    }
                    ConfigComboBox {
                        text: Translation.tr("Rotation")
                        currentValue: displayRow.modelData.transform
                        model: [0, 1, 2, 3, 4, 5, 6, 7].map(t => ({
                            displayName: (t >= 4 ? Translation.tr("Flipped") + " " : "") + (t % 4 * 90) + "°",
                            value: t
                        }))
                        onSelected: value => DisplayConfig.update(displayRow.index, "transform", value)
                    }
                }
                ColumnLayout {
                    GroupedList {
                        ConfigSpinBox {
                            text: "X"
                            value: displayRow.modelData.x
                            from: -32768
                            to: 32768
                            stepSize: 10
                            onValueChanged: if (value !== displayRow.modelData.x)
                                                DisplayConfig.update(displayRow.index, "x", value)
                        }
                        ConfigSpinBox {
                            text: "Y"
                            value: displayRow.modelData.y
                            from: -32768
                            to: 32768
                            stepSize: 10
                            onValueChanged: if (value !== displayRow.modelData.y)
                                                DisplayConfig.update(displayRow.index, "y", value)
                        }
                    }
                }
            }
        }
    }

    function logicalSize(m) {
        const size = m.mode.split("@")[0].split("x").map(Number);
        return {
            width: size[m.transform % 2 ? 1 : 0] / m.scale,
            height: size[m.transform % 2 ? 0 : 1] / m.scale
        };
    }
}
