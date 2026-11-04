pragma Singleton

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    function load() {}

    readonly property var kinds: [UPowerDeviceType.Mouse, UPowerDeviceType.Keyboard, UPowerDeviceType.Headset,
        UPowerDeviceType.Headphones, UPowerDeviceType.GamingInput, UPowerDeviceType.Touchpad,
        UPowerDeviceType.Tablet, UPowerDeviceType.Phone]

    readonly property var devices: UPower.devices.values.filter(dev => dev.isPresent && root.kinds.includes(dev.type))
    readonly property var indicators: readings(devices, BluetoothStatus.connectedDevices)

    function readings(powerDevices, bluetoothDevices) {
        const bluetooth = bluetoothDevices.filter(dev => dev.connected && dev.batteryAvailable);
        const result = bluetooth.map(dev => ({id: dev.address, name: dev.name,
            percentage: dev.battery, charging: false, icon: Icons.getBluetoothDeviceMaterialSymbol(dev.icon || "")}));
        for (const dev of powerDevices) {
            const path = dev.nativePath.toLowerCase().replace(/[^a-z0-9]/g, "");
            if (bluetooth.some(bt => path.includes(bt.address.toLowerCase().replace(/[^a-z0-9]/g, ""))
                || (dev.model && dev.model.toLowerCase() === bt.name.toLowerCase()))) continue;
            result.push({id: dev.nativePath, name: dev.model || Translation.tr("Device"), percentage: dev.percentage,
                charging: dev.state === UPowerDeviceState.Charging,
                icon: dev.type === UPowerDeviceType.Mouse ? "mouse" : dev.type === UPowerDeviceType.Keyboard ? "keyboard"
                    : [UPowerDeviceType.Headset, UPowerDeviceType.Headphones].includes(dev.type) ? "headphones" : "devices"});
        }
        return result;
    }

    function isDraining(dev) {
        return dev.state !== UPowerDeviceState.Charging && dev.state !== UPowerDeviceState.FullyCharged
    }

    function isLow(dev) {
        return dev.percentage > 0 && dev.percentage <= Config.options.battery.peripheralLow / 100 && root.isDraining(dev)
    }

    function isCritical(dev) {
        return dev.percentage > 0 && dev.percentage <= Config.options.battery.peripheralCritical / 100 && root.isDraining(dev)
    }

    readonly property var lowDevices: root.devices.filter(dev => root.isLow(dev))

    Instantiator {
        model: ScriptModel {
            values: root.devices
            objectProp: "nativePath"
        }
        delegate: QtObject {
            id: tracker
            required property var modelData
            readonly property string name: modelData.model || Translation.tr("Device")
            property bool ready: false
            property int notifiedLevel: 0
            readonly property int level: root.isCritical(modelData) ? 2 : root.isLow(modelData) ? 1 : 0
            Component.onCompleted: { ready = true; notifyIfNeeded(); }
            onLevelChanged: notifyIfNeeded()

            function notifyIfNeeded() {
                if (!ready) return;
                if (level === 0) { notifiedLevel = 0; return; }
                if (level <= notifiedLevel || !Config.options.battery.peripheralNotify) return;
                notifiedLevel = level;
                Quickshell.execDetached([
                    "notify-send", "-a", "Shell", "-u", level === 2 ? "critical" : "normal",
                    "--hint=int:transient:1",
                    level === 2 ? Translation.tr("%1 battery critically low").arg(tracker.name) : Translation.tr("%1 battery low").arg(tracker.name),
                    Translation.tr("%1% remaining, please charge it").arg(Math.round(modelData.percentage * 100))
                ]);
            }
        }
    }
}
