pragma Singleton

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import Quickshell.Io

Singleton {
    id: root
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice?.percentage ?? 1
    readonly property bool allowAutomaticSuspend: Config.options.battery.automaticSuspend
    readonly property bool soundEnabled: Config.options.sounds.battery

    property bool isLow: available && (percentage <= Config.options.battery.low / 100)
    property bool isCritical: available && (percentage <= Config.options.battery.critical / 100)
    property bool isSuspending: available && (percentage <= Config.options.battery.suspend / 100)
    property bool isFull: available && (percentage >= Config.options.battery.full / 100)

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging
    property bool isFullAndCharging: isFull && isCharging

    property real energyRate: UPower.displayDevice.changeRate
    property real timeToEmpty: UPower.displayDevice.timeToEmpty
    property real timeToFull: UPower.displayDevice.timeToFull
    readonly property real energy: UPower.displayDevice?.energy ?? 0
    readonly property real energyCapacity: UPower.displayDevice?.energyCapacity ?? 0
    readonly property string model: UPower.displayDevice?.model ?? ""
    readonly property int powerProfile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile

    function setPowerProfile(profile) {
        PowerProfiles.profile = profile
    }

    // Charge limit (charge_control_end_threshold exposed by some laptops)
    readonly property string nativePath: UPower.displayDevice?.nativePath ?? ""
    readonly property string chargeLimitPath: nativePath !== "" ? `${nativePath}/charge_control_end_threshold` : ""
    readonly property int chargeLimitMin: 50
    readonly property int chargeLimitMax: 100
    property bool chargeLimitSupported: false
    property int chargeLimit: 100

    function setChargeLimit(value) {
        if (!root.chargeLimitSupported)
            return
        const clamped = Math.max(root.chargeLimitMin, Math.min(root.chargeLimitMax, Math.round(value)))
        root.chargeLimit = clamped
        writeChargeLimit.running = false
        writeChargeLimit.command = ["sh", "-c", `printf '%s\\n' '${clamped}' > '${root.chargeLimitPath}'`]
        writeChargeLimit.running = true
    }

    onChargeLimitPathChanged: {
        root.chargeLimitSupported = false
        if (root.chargeLimitPath !== "")
            readChargeLimit.running = true
    }

    Component.onCompleted: {
        if (root.chargeLimitPath !== "")
            readChargeLimit.running = true
    }

    Process {
        id: readChargeLimit
        command: ["sh", "-c", `test -w '${root.chargeLimitPath}' && cat '${root.chargeLimitPath}'`]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(text.trim())
                if (!isNaN(value)) {
                    root.chargeLimit = value
                    root.chargeLimitSupported = true
                }
            }
        }
        onExited: (code) => {
            if (code !== 0)
                root.chargeLimitSupported = false
        }
    }

    Process {
        id: writeChargeLimit
        onExited: (code) => {
            readChargeLimit.running = true
        }
    }
    property int chargeCycles: (function() {
        const devList = UPower.devices.values;
        for (let i = 0; i < devList.length; ++i) {
            const dev = devList[i];
            if (dev.isLaptopBattery) {
                return dev.chargeCycles ?? 0;
            }
        }
        return 0;
    })()

    property real health: (function() {
        const devList = UPower.devices.values;
        for (let i = 0; i < devList.length; ++i) {
            const dev = devList[i];
            if (dev.isLaptopBattery && dev.healthSupported) {
                const health = dev.healthPercentage;
                if (health === 0) {
                    return 0.01;
                } else if (health < 1) {
                    return health * 100;
                } else {
                    return health;
                }
            }
        }
        // Fallback: calculate from energy capacity
        for (let i = 0; i < devList.length; ++i) {
            const dev = devList[i];
            if (dev.isLaptopBattery) {
                const energyFull = dev.energyFull ?? 0;
                const energyFullDesign = dev.energyFullDesign ?? 0;
                if (energyFullDesign > 0 && energyFull > 0) {
                    return (energyFull / energyFullDesign) * 100;
                }
            }
        }
        return 0;
    })()


    onIsLowAndNotChargingChanged: {
        if (!root.available || !isLowAndNotCharging) return;
        Quickshell.execDetached([
            "notify-send", 
            Translation.tr("Low battery"), 
            Translation.tr("Consider plugging in your device"), 
            "-u", "critical",
            "-a", "Shell",
            "--hint=int:transient:1",
        ])

        if (root.soundEnabled) Audio.playSystemSound("dialog-warning");
    }

    onIsCriticalAndNotChargingChanged: {
        if (!root.available || !isCriticalAndNotCharging) return;
        Quickshell.execDetached([
            "notify-send", 
            Translation.tr("Critically low battery"), 
            Translation.tr("Please charge!\nAutomatic suspend triggers at %1%").arg(Config.options.battery.suspend), 
            "-u", "critical",
            "-a", "Shell",
            "--hint=int:transient:1",
        ]);

        if (root.soundEnabled) Audio.playSystemSound("suspend-error");
    }

    onIsSuspendingAndNotChargingChanged: {
        if (root.available && isSuspendingAndNotCharging) {
            Quickshell.execDetached(["bash", "-c", `systemctl suspend || loginctl suspend`]);
        }
    }

    onIsFullAndChargingChanged: {
        if (!root.available || !isFullAndCharging) return;
        Quickshell.execDetached([
            "notify-send",
            Translation.tr("Battery full"),
            Translation.tr("Please unplug the charger"),
            "-a", "Shell",
            "--hint=int:transient:1",
        ]);

        if (root.soundEnabled) Audio.playSystemSound("complete");
    }

    onIsPluggedInChanged: {
        if (!root.available || !root.soundEnabled) return;
        if (isPluggedIn) {
            Audio.playSystemSound("power-plug")
        } else {
            Audio.playSystemSound("power-unplug")
        }
    }
}
