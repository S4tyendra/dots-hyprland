pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Samples battery percentage over time and keeps a month of history,
 * persisted to `user/battery-history.json` in the shell state dir.
 */
Singleton {
    id: root
    readonly property int sampleIntervalMs: 10 * 60 * 1000 // 10 minutes
    readonly property int maxAgeMs: 30 * 24 * 60 * 60 * 1000 // 30 days
    readonly property int maxSamples: 6000

    property var samples: []
    property bool loaded: false

    function prune() {
        const cutoff = Date.now() - maxAgeMs
        let drop = 0
        while (drop < samples.length && samples[drop].t < cutoff) {
            drop++
        }
        if (drop > 0)
            samples = samples.slice(drop)
        if (samples.length > maxSamples)
            samples = samples.slice(samples.length - maxSamples)
    }

    function record(force) {
        if (!loaded || !Battery.available)
            return
        const now = Date.now()
        const percent = Math.round(Battery.percentage * 1000) / 10
        const charging = Battery.isCharging
        const last = samples.length > 0 ? samples[samples.length - 1] : null
        if (last) {
            if (now - last.t < 60000 && last.pct === percent)
                return
            if (!force && last.pct === percent && last.charging === charging && now - last.t < sampleIntervalMs)
                return
        }
        samples.push({
            t: now,
            pct: percent,
            charging: charging,
            rate: Math.round(Battery.energyRate * 100) / 100
        })
        prune()
        root.samples = samples.slice(0)
        saveTimer.restart()
    }

    function save() {
        try {
            historyFile.setText(JSON.stringify(root.samples))
        } catch (e) {
            console.warn("[BatteryHistory] Failed to save:", e)
        }
    }

    function clear() {
        samples = []
        save()
    }

    function load() {
        historyFile.reload()
    }

    Timer {
        id: saveTimer
        interval: 1000
        repeat: false
        onTriggered: root.save()
    }

    Timer {
        interval: root.sampleIntervalMs
        running: root.loaded && Battery.available
        repeat: true
        onTriggered: root.record(false)
    }

    Connections {
        target: Battery
        function onIsChargingChanged() {
            root.record(true)
        }
    }

    FileView {
        id: historyFile
        path: Qt.resolvedUrl(Directories.batteryHistoryPath)
        onLoaded: {
            try {
                const parsed = JSON.parse(historyFile.text())
                root.samples = Array.isArray(parsed) ? parsed : []
            } catch (e) {
                console.warn("[BatteryHistory] Invalid history file, starting fresh:", e)
                root.samples = []
            }
            root.loaded = true
            root.record(true)
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                root.loaded = true
                root.record(true)
                root.save()
            } else {
                console.warn("[BatteryHistory] Failed to load history:", error)
                root.loaded = true
            }
        }
    }
}
