import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    property string descriptionMode: {
        if (Config.options.profile.descriptionText === "::uptime::") return "uptime"
        return "distro"
    }

    FolderListModel {
        id: avatarFolderModel
        folder: Config.options.profile.avatarPath !== "" ? Qt.resolvedUrl(Config.options.profile.avatarPath) : ""
        showDirs: false
        nameFilters: ["*.png", "*.svg", "*.jpg", "*.jpeg", "*.webp"]
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            title: Translation.tr("Avatar")

            GroupedList {
                Item {
                    Layout.fillWidth: true
                    implicitHeight: avatarField.implicitHeight + 8

                    MaterialTextArea {
                        id: avatarField
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        placeholderText: Translation.tr("Avatar folder path (e.g. /home/user/Pictures/avatars)")
                        text: Config.options.profile.avatarPath

                        onTextChanged: {
                            avatarDebounceTimer.restart()
                        }

                        Timer {
                            id: avatarDebounceTimer
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                Config.options.profile.avatarPath = avatarField.text
                            }
                        }
                    }
                }

                Flow {
                    id: avatarFlow
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 8
                    visible: Config.options.profile.avatarPath !== "" && avatarFolderModel.count > 0

                    Repeater {
                        model: avatarFolderModel
                        delegate: Rectangle {
                            required property string fileName
                            required property string filePath
                            width: 56
                            height: 56
                            radius: width / 2
                            color: Appearance.colors.colLayer2

                            property bool isSelected: FileUtils.trimFileProtocol(filePath.toString()) === Config.options.profile.avatarPicture

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: filePath
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: width * 2
                                sourceSize.height: height * 2
                            }

                            Rectangle {
                                visible: parent.isSelected
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                width: 18
                                height: 18
                                radius: width / 2
                                color: Appearance.colors.colPrimary

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "check"
                                    iconSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnPrimary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.options.profile.avatarPicture = FileUtils.trimFileProtocol(filePath.toString())
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: Config.options.profile.avatarPath === "" || avatarFolderModel.count === 0
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "image"
                        iconSize: 32
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Set an avatar folder above to browse images")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Identity")

                GroupedList {
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: displayNameField.implicitHeight + 8

                        MaterialTextArea {
                            id: displayNameField
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            placeholderText: SystemInfo.username
                            text: Config.options.profile.displayName

                            onTextChanged: {
                                displayNameDebounceTimer.restart()
                            }

                            Timer {
                                id: displayNameDebounceTimer
                                interval: 800
                                running: false
                                onTriggered: {
                                    Config.options.profile.displayName = displayNameField.text
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 48

                        StyledText {
                            text: Translation.tr("Description")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        ConfigSelectionArray {
                            currentValue: page.descriptionMode
                            onSelected: newValue => {
                                if (newValue === "distro") Config.options.profile.descriptionText = "::distro::"
                                if (newValue === "uptime") Config.options.profile.descriptionText = "::uptime::"
                            }
                            options: [
                                { displayName: Translation.tr("Distro"), icon: "deployed_code", value: "distro" },
                                { displayName: Translation.tr("Uptime"), icon: "timelapse",     value: "uptime" },
                            ]
                        }
                    }
                }
            }
        }
    }
}
