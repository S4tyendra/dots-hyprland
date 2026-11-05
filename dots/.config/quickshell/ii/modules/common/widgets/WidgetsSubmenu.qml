pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: 284
    implicitHeight: Math.min(col.implicitHeight + 16, 720)
    clip: true

    readonly property var widgetList: [
        { key: "visualizer",  icon: "graphic_eq",         name: Translation.tr("Visualizer") },
        { key: "customImage", icon: "image",              name: Translation.tr("Custom Image") },
        { key: "weather",     icon: "partly_cloudy_day",  name: Translation.tr("Weather") },
        { key: "clock",       icon: "schedule",           name: Translation.tr("Clock") },
        { key: "media",       icon: "music_note",         name: Translation.tr("Media") },
        { key: "images",      icon: "photo_library",      name: Translation.tr("Image Converter") },
        { key: "resources",   icon: "monitor_heart",      name: Translation.tr("Resources") },
        { key: "calendar",    icon: "calendar_month",     name: Translation.tr("Calendar") },
        { key: "worldClock",  icon: "public",             name: Translation.tr("World Clock") },
        { key: "userCard",    icon: "person",              name: Translation.tr("User Card") },
    ]

    readonly property var foldableWidgets: widgetList.filter(w => w.key !== "visualizer")

    function foldersCopy() {
        return JSON.parse(JSON.stringify(Config.options.background.widgets.folders ?? []));
    }

    function writeFolders(next) {
        Config.options.background.widgets.folders = next;
    }

    function addFolder() {
        const next = foldersCopy();
        next.push({
            id: "folder-" + Date.now(),
            enable: true,
            name: Translation.tr("Folder"),
            icon: "folder",
            cover: "",
            children: [],
            placementStrategy: "free",
            x: 96,
            y: 96
        });
        writeFolders(next);
    }

    function patchFolder(id, patch) {
        const next = foldersCopy();
        for (let i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                Object.assign(next[i], patch);
                break;
            }
        }
        writeFolders(next);
    }

    function removeFolder(id) {
        writeFolders(foldersCopy().filter(f => f.id !== id));
    }

    function toggleChild(id, key, on) {
        const next = foldersCopy();
        for (let i = 0; i < next.length; i++) {
            if (next[i].id !== id)
                continue;
            let children = next[i].children ?? [];
            const has = children.indexOf(key) >= 0;
            if (on && !has)
                children = children.concat([key]);
            if (!on && has)
                children = children.filter(c => c !== key);
            next[i].children = children;
            break;
        }
        writeFolders(next);
    }

    function coverName(key) {
        if (!key)
            return Translation.tr("Folder icon");
        const hit = root.foldableWidgets.find(w => w.key === key);
        return hit ? hit.name : key;
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colLayer0
    }

    StyledFlickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        contentWidth: width
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: flick.width
            spacing: 2

            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "lock"
                text: Translation.tr("Lock widget positions")
                checked: Config.options.background.widgetsLocked ?? false
                onCheckedChanged: Config.options.background.widgetsLocked = checked
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.4
            }

            Repeater {
                model: root.widgetList
                delegate: ConfigSwitch {
                    required property var modelData
                    Layout.fillWidth: true
                    buttonIcon: modelData.icon
                    text: modelData.name
                    checked: Config.options.background.widgets[modelData.key]?.enable ?? false
                    onCheckedChanged: {
                        if (Config.options.background.widgets[modelData.key]) {
                            Config.options.background.widgets[modelData.key].enable = checked
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.4
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 4
                MaterialSymbol {
                    text: "folder"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Widget folders")
                    color: Appearance.colors.colOnLayer0
                }
                RippleButton {
                    implicitHeight: 28
                    implicitWidth: addLabel.implicitWidth + 16
                    buttonRadius: Appearance.rounding.small
                    onClicked: root.addFolder()
                    contentItem: StyledText {
                        id: addLabel
                        anchors.centerIn: parent
                        text: Translation.tr("Add")
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            Repeater {
                model: Config.options.background.widgets.folders ?? []
                delegate: ColumnLayout {
                    id: folderEditor
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4
                    property bool expanded: true

                    RowLayout {
                        Layout.fillWidth: true
                        ConfigSwitch {
                            Layout.fillWidth: true
                            buttonIcon: modelData.icon ?? "folder"
                            text: modelData.name || Translation.tr("Folder")
                            checked: modelData.enable !== false
                            onCheckedChanged: {
                                if ((modelData.enable !== false) === checked)
                                    return;
                                root.patchFolder(modelData.id, { enable: checked });
                            }
                        }
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: 16
                            onClicked: folderEditor.expanded = !folderEditor.expanded
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: folderEditor.expanded ? "expand_less" : "expand_more"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: folderEditor.expanded
                        spacing: 6

                        MaterialTextField {
                            id: folderNameField
                            Layout.fillWidth: true
                            wrapMode: TextInput.NoWrap
                            placeholderText: Translation.tr("Folder name")
                            text: modelData.name ?? ""
                            onEditingFinished: {
                                root.patchFolder(modelData.id, { name: text });
                                folderNameField.focus = false;
                            }
                            Keys.onEscapePressed: folderNameField.focus = false
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                propagateComposedEvents: true
                                cursorShape: Qt.IBeamCursor
                                onPressed: mouse => {
                                    folderNameField.forceActiveFocus();
                                    mouse.accepted = false;
                                }
                            }
                        }

                        StyledText {
                            Layout.leftMargin: 4
                            text: Translation.tr("Outer widget") + " · " + root.coverName(modelData.cover ?? "")
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.7
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 5
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: [{ key: "", icon: "folder", name: Translation.tr("Folder icon") }].concat(root.foldableWidgets)
                                delegate: RippleButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    buttonRadius: Appearance.rounding.small
                                    toggled: (folderEditor.modelData.cover ?? "") === modelData.key
                                    colBackground: toggled ? Appearance.colors.colSecondaryContainer : "transparent"
                                    onClicked: root.patchFolder(folderEditor.modelData.id, { cover: modelData.key })
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        iconSize: 20
                                        color: Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                        }

                        StyledText {
                            Layout.leftMargin: 4
                            text: Translation.tr("Widgets inside")
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.7
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        Repeater {
                            model: root.foldableWidgets
                            delegate: ConfigSwitch {
                                required property var modelData
                                Layout.fillWidth: true
                                buttonIcon: modelData.icon
                                text: modelData.name
                                checked: (folderEditor.modelData.children ?? []).indexOf(modelData.key) >= 0
                                onCheckedChanged: {
                                    const has = (folderEditor.modelData.children ?? []).indexOf(modelData.key) >= 0;
                                    if (checked === has)
                                        return;
                                    root.toggleChild(folderEditor.modelData.id, modelData.key, checked);
                                }
                            }
                        }

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            onClicked: root.removeFolder(folderEditor.modelData.id)
                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: Translation.tr("Delete folder")
                                color: Appearance.colors.colError
                            }
                        }
                    }
                }
            }
        }
    }
}
