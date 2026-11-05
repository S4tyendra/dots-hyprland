import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// GPU-composited bars. The old Canvas 2D path ran JS + CPU raster +
// MultiEffect blur at cava's framerate on the GUI thread (~60fps).
Item {
    id: root
    property list<var> points
    property list<var> smoothPoints
    property real maxVisualizerValue: 850
    property int smoothing: 1
    property real nonLinearCurve: 0.72
    property bool live: true
    property color color: Appearance.m3colors.m3primary

    readonly property int barCount: Math.max(8, Math.min(points.length || 0, 48))

    Row {
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.live ? root.barCount : 0
            delegate: Rectangle {
                required property int index
                width: Math.max(1, (root.width - (root.barCount - 1) * 2) / root.barCount)
                anchors.bottom: parent.bottom
                height: {
                    if (!root.live || !root.points || root.points.length === 0)
                        return 2;
                    const n = root.points.length;
                    const src = Math.min(n - 1, Math.floor(index * n / root.barCount));
                    let sum = 0, count = 0;
                    const w = root.smoothing;
                    for (let j = -w; j <= w; ++j) {
                        const idx = Math.max(0, Math.min(n - 1, src + j));
                        sum += root.points[idx];
                        count++;
                    }
                    const norm = Math.min(1.0, Math.max(0.0, (sum / count) / (root.maxVisualizerValue || 1)));
                    const scaled = Math.pow(norm, root.nonLinearCurve);
                    return Math.max(2, scaled * root.height);
                }
                radius: width / 2
                color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.45)
            }
        }
    }
}
