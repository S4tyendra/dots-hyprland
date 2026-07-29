import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root

    spacing: 4

    MaterialTextArea {
        id: field
        Layout.fillWidth: true
        placeholderText: Translation.tr("City name")
        text: Config.options.bar.weather.city
        wrapMode: TextEdit.Wrap
        onTextChanged: {
            Qt.callLater(() => {
                Config.options.bar.weather.city = text;
                searchTimer.restart();
            });
        }
    }

    Timer {
        id: searchTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (field.text.length >= 2) {
                doCitySearch(field.text);
            } else {
                resultsModel.clear();
            }
        }
    }

    Repeater {
        model: resultsModel.count > 0 ? resultsModel : null

        delegate: Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Appearance.rounding.small
            color: delegateHover.containsMouse ? Appearance.colors.colSurfaceContainerHighest : Appearance.colors.colSurfaceContainerHigh

            MouseArea {
                id: delegateHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    const display = model.displayName;
                    field.text = display;
                    resultsModel.clear();
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                MaterialSymbol {
                    fill: 0
                    text: "location_on"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    StyledText {
                        text: model.displayName
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: model.cityName + ", " + model.country
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 0.7
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    ListModel { id: resultsModel }

    property var searchProcess: null

    function doCitySearch(query) {
        const apiKey = Config.options.bar.weather.apiKey;
        if (!apiKey || apiKey.length === 0) return;

        const url = `https://api.weather.com/v3/location/search?query=${encodeURIComponent(query)}&language=en-US&format=json&apiKey=${apiKey}`;

        if (!searchProcess) {
            searchProcess = citySearchComp.createObject(root);
        }
        searchProcess.command = ["bash", "-c", `curl -s "${url}"`];
        searchProcess.running = true;
    }

    function handleSearchResult(text) {
        resultsModel.clear();
        if (!text || text.length === 0) return;

        try {
            const parsed = JSON.parse(text);
            const loc = parsed?.location;
            if (!loc) return;

            const count = loc.latitude?.length || 0;
            for (let i = 0; i < Math.min(count, 5); i++) {
                const displayName = loc.displayName?.[i] || loc.city?.[i] || "";
                const cityName = loc.city?.[i] || displayName;
                const country = loc.country?.[i] || "";

                if (displayName) {
                    resultsModel.append({
                        displayName: displayName,
                        cityName: cityName,
                        country: country
                    });
                }
            }
        } catch (e) {
            console.error(`[CitySearch] ${e.message}`);
        }
    }

    Component {
        id: citySearchComp
        Process {
            command: ["bash", "-c", ""]
            stdout: StdioCollector {
                onStreamFinished: root.handleSearchResult(text)
            }
        }
    }
}
