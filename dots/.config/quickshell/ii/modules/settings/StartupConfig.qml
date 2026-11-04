import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    readonly property var settings: Config.options.hyprland.autostartApps

    function update(index, key, value) {
        const apps = Array.from(settings.apps).map(a => Object.assign({}, a));
        apps[index][key] = value;
        settings.apps = apps;
    }

    ContentSection {
        icon: "rocket_launch"
        title: Translation.tr("Startup apps")
        GroupedList {
            ConfigSwitch {
                text: Translation.tr("Launch configured apps at login")
                buttonIcon: "power_settings_new"
                checked: page.settings.enable
                onCheckedChanged: page.settings.enable = checked
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr(
                      "Commands run once at the next Hyprland login. Workspace 0 uses the current workspace. Apps already started by your Hyprland config do not need another entry here.")
            wrapMode: Text.Wrap
        }
        Repeater {
            model: page.settings.apps
            ColumnLayout {
                id: appRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                GroupedList {
                    ConfigTextArea {
                        text: Translation.tr("Command")
                        placeholderText: "firefox"
                        value: appRow.modelData.cmd
                        textArea.onEditingFinished: page.update(appRow.index, "cmd", value)
                    }
                    ConfigSpinBox {
                        text: Translation.tr("Workspace (0 = current)")
                        value: appRow.modelData.workspace
                        from: 0
                        to: 100
                        onValueChanged: if (value !== appRow.modelData.workspace)
                                            page.update(appRow.index, "workspace", value)
                    }
                    ConfigSpinBox {
                        text: Translation.tr("Delay (seconds)")
                        value: appRow.modelData.delay
                        from: 0
                        to: 300
                        onValueChanged: if (value !== appRow.modelData.delay)
                                            page.update(appRow.index, "delay", value)
                    }
                }
                RippleButtonWithIcon {
                    Layout.alignment: Qt.AlignRight
                    materialIcon: "delete"
                    mainText: Translation.tr("Remove app")
                    onClicked: page.settings.apps = Array.from(page.settings.apps).filter((_, i) => i
                                                                                                    !== appRow.index)
                }
            }
        }
        RippleButtonWithIcon {
            materialIcon: "add"
            mainText: Translation.tr("Add app")
            onClicked: page.settings.apps = [...page.settings.apps,
                                             {
                                                 cmd: "",
                                                 workspace: 0,
                                                 delay: 0
                                             }
                       ]
        }
    }
}
