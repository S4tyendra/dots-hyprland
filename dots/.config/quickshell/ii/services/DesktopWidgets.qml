pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    readonly property var catalog: [
        {key: "clock", name: Translation.tr("Clock")},
        {key: "weather", name: Translation.tr("Weather")},
        {key: "media", name: Translation.tr("Media")},
        {key: "resources", name: Translation.tr("Resources")},
        {key: "userCard", name: Translation.tr("User card")},
        {key: "calendar", name: Translation.tr("Calendar")},
        {key: "customImage", name: Translation.tr("Custom image")},
        {key: "images", name: Translation.tr("Image converter")},
        {key: "worldClock", name: Translation.tr("World clock")},
        {key: "visualizer", name: Translation.tr("Visualizer")}
    ]
    function showOn(key, monitor) {
        const selected = Config.options.background.widgets[key].monitor;
        return selected === "" || selected === monitor;
    }
}
