import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true
    ContentSection {
        icon: "widgets"
        title: Translation.tr("Desktop widgets")
        GroupedList {
            ConfigSwitch {
                text: Translation.tr("Lock widget positions")
                buttonIcon: "lock"
                checked: Config.options.background.widgetsLocked
                onCheckedChanged: Config.options.background.widgetsLocked = checked
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr(
                      "Enable widgets here and choose their display and size. Unlock positions to drag widgets on the desktop; Background contains their detailed style controls.")
            wrapMode: Text.Wrap
        }
        Repeater {
            model: DesktopWidgets.catalog
            ColumnLayout {
                id: row
                required property var modelData
                readonly property var entry: Config.options.background.widgets[modelData.key]
                Layout.fillWidth: true
                GroupedList {
                    ConfigSwitch {
                        text: row.modelData.name
                        buttonIcon: "widgets"
                        checked: row.entry.enable
                        onCheckedChanged: row.entry.enable = checked
                    }
                    ConfigComboBox {
                        text: Translation.tr("Display")
                        enabled: row.entry.enable
                        currentValue: row.entry.monitor
                        model: [
                            {
                                displayName: Translation.tr("All displays"),
                                value: ""
                            },
                            ...Quickshell.screens.map(s => ({
                                displayName: s.name,
                                value: s.name
                            })), ...(!Quickshell.screens.some(s => s.name === row.entry.monitor)
                                     && row.entry.monitor !== "" ? [
                                                                       {
                                                                           displayName: row.entry.monitor
                                                                                        + " (" + Translation.tr(
                                                                                            "disconnected")
                                                                                        + ")",
                                                                           value: row.entry.monitor
                                                                       }
                                                                   ] : [])]
                        onSelected: value => row.entry.monitor = value
                    }
                    ConfigSpinBox {
                        visible: row.modelData.key !== "visualizer"
                        enabled: row.entry.enable
                        text: Translation.tr("Size (%)")
                        value: Math.round(row.entry.scale * 100)
                        from: 50
                        to: 200
                        stepSize: 10
                        onValueChanged: if (value !== Math.round(row.entry.scale * 100))
                                            row.entry.scale = value / 100
                    }
                    ConfigSpinBox {
                        visible: row.modelData.key === "visualizer"
                        enabled: row.entry.enable
                        text: Translation.tr("Height (pixels)")
                        value: Config.options.background.widgets.visualizer.height
                        from: 50
                        to: 1200
                        stepSize: 50
                        onValueChanged: if (visible)
                                            Config.options.background.widgets.visualizer.height = value
                    }
                }
            }
        }
    }
}
