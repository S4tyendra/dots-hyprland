import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true
    property int rangeHours: 24
    property var chartData: []
    property var stats: ({ min: 0, max: 0, avg: 0, count: 0 })

    function buildChartData() {
        const cutoff = Date.now() - rangeHours * 3600000
        const raw = BatteryHistory.samples.filter(s => s.t >= cutoff)
        if (raw.length <= 240)
            return raw
        const bucket = raw.length / 240
        const out = []
        for (let i = 0; i < 240; i++) {
            const start = Math.floor(i * bucket)
            const end = Math.min(raw.length, Math.floor((i + 1) * bucket))
            let sum = 0, time = 0, n = 0
            for (let j = start; j < end; j++) {
                sum += raw[j].pct
                time += raw[j].t
                n++
            }
            if (n > 0)
                out.push({ t: time / n, pct: sum / n })
        }
        return out
    }

    function refresh() {
        const cutoff = Date.now() - rangeHours * 3600000
        const raw = BatteryHistory.samples.filter(s => s.t >= cutoff)
        let min = 100, max = 0, sum = 0
        for (let i = 0; i < raw.length; i++) {
            min = Math.min(min, raw[i].pct)
            max = Math.max(max, raw[i].pct)
            sum += raw[i].pct
        }
        stats = {
            min: raw.length > 0 ? min : 0,
            max: raw.length > 0 ? max : 0,
            avg: raw.length > 0 ? sum / raw.length : 0,
            count: raw.length
        }
        chartData = buildChartData()
        chart.requestPaint()
    }

    onRangeHoursChanged: refresh()

    Connections {
        target: BatteryHistory
        function onSamplesChanged() {
            page.refresh()
        }
    }

    Component.onCompleted: refresh()

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Status")

        Flow {
            Layout.fillWidth: true
            spacing: 6

            ResourceCard {
                label: Translation.tr("Health")
                iconText: "heart_check"
                iconShape: MaterialShape.Shape.Clover4Leaf
                value: Battery.health > 0 ? Battery.health / 100 : 0
                percentText: Battery.health > 0 ? `${Math.round(Battery.health)}%` : Translation.tr("N/A")
                sublabel: ""
                showProgress: true
                cardWidth: 170
            }

            ResourceCard {
                label: Translation.tr("Cycles")
                iconText: "cyclone"
                iconShape: MaterialShape.Shape.Pentagon
                value: Battery.chargeCycles > 0 ? Math.min(Battery.chargeCycles / 1000, 1) : 0
                percentText: Battery.chargeCycles > 0 ? `${Battery.chargeCycles}` : Translation.tr("N/A")
                sublabel: Battery.model
                showProgress: true
                cardWidth: 170
            }

            ResourceCard {
                label: Translation.tr("Capacity")
                iconText: "battery_android_full"
                iconShape: MaterialShape.Shape.Clover4Leaf
                value: Battery.energyCapacity > 0 ? Math.min(Battery.energy / Battery.energyCapacity, 1) : 0
                percentText: Battery.energyCapacity > 0 ? `${Battery.energyCapacity.toFixed(0)}Wh` : Translation.tr("N/A")
                sublabel: Battery.energyCapacity > 0 ? `${Battery.energy.toFixed(1)} Wh ${Translation.tr("now")}` : ""
                showProgress: false
                cardWidth: 170
            }
        }
    }

    ContentSection {
        icon: "monitoring"
        title: Translation.tr("History")

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            SelectionGroupButton {
                buttonText: Translation.tr("24h")
                toggled: page.rangeHours === 24
                leftmost: true
                onClicked: page.rangeHours = 24
            }
            SelectionGroupButton {
                buttonText: Translation.tr("7d")
                toggled: page.rangeHours === 24 * 7
                onClicked: page.rangeHours = 24 * 7
            }
            SelectionGroupButton {
                buttonText: Translation.tr("30d")
                toggled: page.rangeHours === 24 * 30
                rightmost: true
                onClicked: page.rangeHours = 24 * 30
            }

            Item { Layout.fillWidth: true }

            StyledText {
                visible: page.stats.count > 0
                text: `${Translation.tr("Min")} ${Math.round(page.stats.min)}% · ${Translation.tr("Avg")} ${Math.round(page.stats.avg)}% · ${Translation.tr("Max")} ${Math.round(page.stats.max)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            Layout.topMargin: 6

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1

                Canvas {
                    id: chart
                    anchors.fill: parent
                    anchors.margins: 8

                    onWidthChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        const padLeft = 30
                        const padRight = 6
                        const padTop = 6
                        const padBottom = 20
                        const plotWidth = width - padLeft - padRight
                        const plotHeight = height - padTop - padBottom
                        if (plotWidth <= 0 || plotHeight <= 0)
                            return

                        // Horizontal grid
                        ctx.lineWidth = 1
                        ctx.font = "10px sans-serif"
                        ctx.textAlign = "right"
                        ctx.textBaseline = "middle"
                        for (let value = 0; value <= 100; value += 25) {
                            const y = padTop + plotHeight * (1 - value / 100)
                            ctx.strokeStyle = Appearance.colors.colOutline
                            ctx.beginPath()
                            ctx.moveTo(padLeft, y)
                            ctx.lineTo(width - padRight, y)
                            ctx.stroke()
                            ctx.fillStyle = Appearance.colors.colSubtext
                            ctx.fillText(`${value}%`, padLeft - 4, y)
                        }

                        const points = page.chartData
                        if (points.length < 2)
                            return

                        const now = Date.now()
                        const startTime = now - page.rangeHours * 3600000
                        const timeSpan = Math.max(1, now - startTime)

                        ctx.beginPath()
                        for (let i = 0; i < points.length; i++) {
                            const x = padLeft + Math.max(0, Math.min(1, (points[i].t - startTime) / timeSpan)) * plotWidth
                            const y = padTop + plotHeight * (1 - points[i].pct / 100)
                            if (i === 0)
                                ctx.moveTo(x, y)
                            else
                                ctx.lineTo(x, y)
                        }
                        ctx.strokeStyle = Appearance.colors.colPrimary
                        ctx.lineWidth = 2
                        ctx.stroke()

                        // Fill under the line
                        const lastPoint = points[points.length - 1]
                        const lastX = padLeft + Math.max(0, Math.min(1, (lastPoint.t - startTime) / timeSpan)) * plotWidth
                        const firstX = padLeft + Math.max(0, Math.min(1, (points[0].t - startTime) / timeSpan)) * plotWidth
                        ctx.lineTo(lastX, padTop + plotHeight)
                        ctx.lineTo(firstX, padTop + plotHeight)
                        ctx.closePath()
                        ctx.fillStyle = ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                        ctx.fill()

                        // Time labels
                        ctx.fillStyle = Appearance.colors.colSubtext
                        ctx.textAlign = "left"
                        ctx.fillText(Qt.formatDateTime(new Date(startTime), page.rangeHours === 24 ? "MMM d, hh:mm" : "MMM d"), padLeft, height - 8)
                        ctx.textAlign = "right"
                        ctx.fillText(Translation.tr("now"), width - padRight, height - 8)
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: page.chartData.length < 2
                    text: Battery.available
                        ? Translation.tr("Collecting battery data…")
                        : Translation.tr("No battery detected on this device")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Samples are taken every 10 minutes and on charger changes, kept for 30 days.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            RippleButtonWithIcon {
                materialIcon: "delete"
                mainText: Translation.tr("Clear history")
                onClicked: BatteryHistory.clear()
            }
        }
    }
}
