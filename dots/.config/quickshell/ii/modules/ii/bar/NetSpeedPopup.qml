import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    property string downloadToday: "-"
    property string uploadToday: "-"
    property string totalToday: "-"
    property string avgSpeedToday: "-"
    property string activeIface: ""
    property real rxBps: 0
    property real txBps: 0
    property string rxSpeedText: "0 B/s"
    property string txSpeedText: "0 B/s"

    Row {
        spacing: 5

        ResourceCard {
            label: Translation.tr("Download (Today)")
            iconText: "arrow_downward"
            iconShape: MaterialShape.Shape.Clover4Leaf
            value: 0
            percentText: root.rxSpeedText
            showProgress: false
            sublabel: root.downloadToday
        }

        ResourceCard {
            label: Translation.tr("Upload (Today)")
            iconText: "arrow_upward"
            iconShape: MaterialShape.Shape.Gem
            value: 0
            percentText: root.txSpeedText
            showProgress: false
            sublabel: root.uploadToday
        }

        ResourceCard {
            label: Translation.tr("Total Traffic")
            iconText: "speed"
            iconShape: MaterialShape.Shape.Circle
            value: 0
            percentText: root.totalToday
            showProgress: false
            sublabel: root.avgSpeedToday !== "-" ? `${root.avgSpeedToday}` : root.activeIface
        }
    }
}
