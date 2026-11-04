import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property bool darkMode: true
    property string monitorName: ""
    spacing: 8
    Component.onCompleted: searchField.forceActiveFocus()
    RowLayout {
        Layout.fillWidth: true
        MaterialTextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: Translation.tr("Search Wallhaven…")
            text: OnlineWallpapers.query
            onTextEdited: OnlineWallpapers.query = text
            onAccepted: OnlineWallpapers.search()
            Accessible.name: Translation.tr("Search online wallpapers")
        }
        RippleButtonWithIcon {
            materialIcon: "search"
            mainText: Translation.tr("Search")
            enabled: !OnlineWallpapers.loading && !OnlineWallpapers.downloading
            onClicked: OnlineWallpapers.search()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        StyledComboBox {
            Layout.fillWidth: true
            textRole: "displayName"
            model: [{displayName: Translation.tr("Relevance"), value: "relevance"}, {displayName: Translation.tr("Top rated"), value: "toplist"}, {displayName: Translation.tr("Newest"), value: "date_added"}]
            currentIndex: Math.max(0, model.findIndex(m => m.value === OnlineWallpapers.sorting))
            onActivated: OnlineWallpapers.sorting = model[currentIndex].value
            Accessible.name: Translation.tr("Sort wallpapers")
        }
        StyledComboBox {
            Layout.fillWidth: true
            textRole: "displayName"
            model: [{displayName: Translation.tr("Any resolution"), value: ""}, {displayName: "1080p+", value: "1920x1080"}, {displayName: "1440p+", value: "2560x1440"}, {displayName: "4K+", value: "3840x2160"}]
            currentIndex: Math.max(0, model.findIndex(m => m.value === OnlineWallpapers.resolution))
            onActivated: OnlineWallpapers.resolution = model[currentIndex].value
            Accessible.name: Translation.tr("Minimum resolution")
        }
        StyledComboBox {
            Layout.fillWidth: true
            textRole: "displayName"
            model: [{displayName: Translation.tr("All categories"), value: "111"}, {displayName: Translation.tr("General"), value: "100"}, {displayName: Translation.tr("Anime"), value: "010"}, {displayName: Translation.tr("People"), value: "001"}]
            currentIndex: Math.max(0, model.findIndex(m => m.value === OnlineWallpapers.category))
            onActivated: OnlineWallpapers.category = model[currentIndex].value
            Accessible.name: Translation.tr("Wallpaper category")
        }
    }
    StyledText {
        Layout.fillWidth: true
        visible: OnlineWallpapers.error !== ""
        text: OnlineWallpapers.error
        color: Appearance.colors.colError
        wrapMode: Text.Wrap
    }
    StyledIndeterminateProgressBar {
        Layout.fillWidth: true
        visible: OnlineWallpapers.loading || OnlineWallpapers.downloading
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        GridView {
            id: onlineGrid
            anchors.fill: parent
            clip: true
            cellWidth: width / 3
            cellHeight: cellWidth * 0.7 + 24
            model: OnlineWallpapers.results
            keyNavigationEnabled: true
            delegate: RippleButton {
                id: tile
                required property var modelData
                required property int index
                width: onlineGrid.cellWidth - 6
                height: onlineGrid.cellHeight - 6
                enabled: !OnlineWallpapers.downloading && !OnlineWallpapers.loading
                Accessible.name: Translation.tr("Download and apply wallpaper %1, %2").arg(modelData.id).arg(modelData.resolution)
                onClicked: OnlineWallpapers.apply(modelData, root.darkMode, root.monitorName)
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                contentItem: ColumnLayout {
                    Image {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: tile.modelData.thumb
                        sourceSize.width: 300
                        sourceSize.height: 200
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        clip: true
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: tile.modelData.resolution
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }
        }
        StyledText {
            anchors.centerIn: parent
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: onlineGrid.count === 0 && !OnlineWallpapers.loading
            text: Translation.tr("Search to browse online wallpapers. Select an image to download and apply it; downloads stay in Pictures/Wallpapers/Online.")
        }
    }
    RowLayout {
        Layout.fillWidth: true
        RippleButtonWithIcon {
            materialIcon: "chevron_left"; mainText: Translation.tr("Previous")
            enabled: OnlineWallpapers.page > 1 && !OnlineWallpapers.loading && !OnlineWallpapers.downloading
            onClicked: OnlineWallpapers.search(OnlineWallpapers.page - 1)
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: OnlineWallpapers.downloading ? Translation.tr("Downloading…") : Translation.tr("Page %1 · SFW images").arg(OnlineWallpapers.page)
        }
        RippleButtonWithIcon {
            materialIcon: "chevron_right"; mainText: Translation.tr("Next")
            enabled: OnlineWallpapers.page < OnlineWallpapers.lastPage && !OnlineWallpapers.loading && !OnlineWallpapers.downloading
            onClicked: OnlineWallpapers.search(OnlineWallpapers.page + 1)
        }
    }
}
