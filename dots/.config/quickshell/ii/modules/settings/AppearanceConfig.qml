import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    Component.onCompleted: SystemAppearance.refresh()
    function choices(list, current) {
        return [...new Set([current, ...list])].filter(Boolean).map(name => {
            return {
                displayName: name,
                value: name
            };
        });
    }
    ContentSection {
        icon: "palette"
        title: Translation.tr("System appearance")
        GroupedList {
            ConfigComboBox {
                text: Translation.tr("GTK theme")
                enabled: !SystemAppearance.busy
                currentValue: SystemAppearance.draft.gtkTheme
                model: page.choices(SystemAppearance.catalog.gtkThemes, currentValue)
                onSelected: value => SystemAppearance.setDraft("gtkTheme", value)
            }
            ConfigComboBox {
                text: Translation.tr("Qt widget style")
                enabled: !SystemAppearance.busy
                currentValue: SystemAppearance.draft.qtStyle
                model: page.choices(SystemAppearance.catalog.qtStyles, currentValue)
                onSelected: value => SystemAppearance.setDraft("qtStyle", value)
            }
            ConfigComboBox {
                text: Translation.tr("Icon theme")
                enabled: !SystemAppearance.busy
                currentValue: SystemAppearance.draft.iconTheme
                model: page.choices(SystemAppearance.catalog.iconThemes, currentValue)
                onSelected: value => SystemAppearance.setDraft("iconTheme", value)
            }
            ConfigComboBox {
                text: Translation.tr("Cursor theme")
                enabled: !SystemAppearance.busy
                currentValue: SystemAppearance.draft.cursorTheme
                model: page.choices(SystemAppearance.catalog.cursorThemes, currentValue)
                onSelected: value => SystemAppearance.setDraft("cursorTheme", value)
            }
            ConfigSpinBox {
                text: Translation.tr("Cursor size")
                value: SystemAppearance.draft.cursorSize
                from: 16
                to: 96
                stepSize: 4
                onValueChanged: if (value !== SystemAppearance.draft.cursorSize)
                                    SystemAppearance.setDraft("cursorSize", value)
            }
            ConfigTextArea {
                text: Translation.tr("Application font")
                description: Translation.tr("Font family and size, e.g. Noto Sans 11")
                value: SystemAppearance.draft.font
                textArea.onEditingFinished: SystemAppearance.setDraft("font", value)
            }
            ConfigComboBox {
                text: Translation.tr("Shell font")
                currentValue: Config.options.appearance.fonts.main
                model: page.choices(SystemAppearance.catalog.fonts, currentValue)
                onSelected: value => Config.options.appearance.fonts.main = value
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: SystemAppearance.error !== "" || SystemAppearance.message !== ""
            text: SystemAppearance.error || SystemAppearance.message
            color: SystemAppearance.error ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh installed themes")
                enabled: !SystemAppearance.busy
                onClicked: SystemAppearance.refresh()
            }
            RippleButtonWithIcon {
                materialIcon: "check"
                mainText: Translation.tr("Apply appearance")
                enabled: !SystemAppearance.busy
                onClicked: SystemAppearance.apply()
            }
        }
    }
    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper theme templates")
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr(
                      "Choose which apps follow wallpaper colors. Your original Matugen configuration stays intact. Changes take effect the next time colors are generated.")
            wrapMode: Text.Wrap
        }
        GroupedList {
            Repeater {
                model: SystemAppearance.catalog.templates
                ConfigSwitch {
                    required property string modelData
                    buttonIcon: "palette"
                    text: modelData
                    checked: !Config.options.appearance.disabledTemplates.includes(modelData)
                    onCheckedChanged: {
                        const disabled = Array.from(Config.options.appearance.disabledTemplates);
                        if (checked === !disabled.includes(modelData))
                            return;
                        Config.options.appearance.disabledTemplates = checked ? disabled.filter(t => t !== modelData) :
                                                                                [...disabled, modelData];
                    }
                }
            }
        }
        RippleButtonWithIcon {
            materialIcon: "refresh"
            mainText: Translation.tr("Regenerate colors now")
            onClicked: SystemAppearance.regenerate()
        }
    }
}
