import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

StyledPopup {
    id: root

    readonly property var profileOptions: Battery.hasPerformanceProfile
        ? [
            { profile: PowerProfile.PowerSaver, icon: "energy_savings_leaf", name: Translation.tr("Saver") },
            { profile: PowerProfile.Balanced, icon: "airwave", name: Translation.tr("Balanced") },
            { profile: PowerProfile.Performance, icon: "local_fire_department", name: Translation.tr("Performance") }
        ]
        : [
            { profile: PowerProfile.PowerSaver, icon: "energy_savings_leaf", name: Translation.tr("Saver") },
            { profile: PowerProfile.Balanced, icon: "airwave", name: Translation.tr("Balanced") }
        ]

    function formatTime(seconds) {
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return `${h}h, ${m}m`
        return `${m}m`
    }

    readonly property bool showTime: !(Battery.chargeState == 4
        || (Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty) <= 0
        || Battery.energyRate <= 0.01)

    ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 3
            spacing: 7

            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.ClamShell
                text: "battery_android_full"
                iconSize: Appearance.font.pixelSize.large
                implicitSize: 36
                color: Appearance.colors.colPrimaryContainer
                colSymbol: Appearance.colors.colPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -3

                StyledText {
                    text: Translation.tr("Battery")
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.6
                    text: {
                        if (Battery.chargeState == 4)
                            return Translation.tr("Fully charged")
                        if (Battery.isCharging) {
                            if (Battery.timeToFull > 0)
                                return Translation.tr("Charging") + " · " + formatTime(Battery.timeToFull)
                            return Translation.tr("Charging")
                        }
                        if (Battery.percentage <= 0)
                            return Translation.tr("Depleted")
                        if (Battery.timeToEmpty > 0)
                            return Translation.tr("Time to empty") + " · " + formatTime(Battery.timeToEmpty)
                        return Translation.tr("Time to empty")
                    }
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                Layout.rightMargin: 8
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colPrimary
                text: `${Math.round(Battery.percentage * 100)}%`
            }
        }

        RowLayout {
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
                cardWidth: 150
            }

            ResourceCard {
                label: Battery.isCharging
                    ? Translation.tr("Charging")
                    : Translation.tr("Draw")
                iconText: "bolt"
                iconShape: MaterialShape.Shape.Pentagon
                value: Battery.energyRate > 0 ? Math.min(Battery.energyRate / 60, 1.0) : 0
                percentText: `${Battery.energyRate.toFixed(2)}W`
                sublabel: ""
                showProgress: true
                cardWidth: 150
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Battery.chargeCycles > 0 || Battery.energyCapacity > 0

            ResourceCard {
                label: Translation.tr("Cycles")
                iconText: "cyclone"
                iconShape: MaterialShape.Shape.Pentagon
                value: Math.min(Battery.chargeCycles / 1000, 1)
                percentText: Battery.chargeCycles > 0 ? `${Battery.chargeCycles}` : Translation.tr("N/A")
                sublabel: Battery.model
                showProgress: true
                cardWidth: 150
            }

            ResourceCard {
                label: Translation.tr("Capacity")
                iconText: "battery_android_full"
                iconShape: MaterialShape.Shape.Clover4Leaf
                value: Battery.energyCapacity > 0 ? Math.min(Battery.energy / Battery.energyCapacity, 1) : 0
                percentText: Battery.energyCapacity > 0 ? `${Battery.energyCapacity.toFixed(0)}Wh` : Translation.tr("N/A")
                sublabel: Battery.energyCapacity > 0 ? `${Battery.energy.toFixed(1)} Wh ${Translation.tr("now")}` : ""
                showProgress: false
                cardWidth: 150
            }
        }

        // Power profile selection
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: Battery.available

            Repeater {
                model: root.profileOptions

                RippleButton {
                    id: profileButton
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.small
                    toggled: Battery.powerProfile === modelData.profile
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colBackgroundToggled: Appearance.colors.colPrimaryContainer
                    colBackgroundToggledHover: Appearance.colors.colPrimaryContainerHover
                    onClicked: Battery.setPowerProfile(modelData.profile)

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: 16
                            color: profileButton.toggled
                                ? Appearance.colors.colOnPrimaryContainer
                                : Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: profileButton.toggled
                                ? Appearance.colors.colOnPrimaryContainer
                                : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        // Charge limit, only on laptops that expose a writable threshold
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 3
            Layout.rightMargin: 3
            spacing: 8
            visible: Battery.chargeLimitSupported

            MaterialSymbol {
                text: "battery_charging_full"
                iconSize: 18
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: Translation.tr("Charge limit")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledSlider {
                Layout.fillWidth: true
                from: Battery.chargeLimitMin
                to: Battery.chargeLimitMax
                stepSize: 5
                value: Battery.chargeLimit
                configuration: StyledSlider.Configuration.XS
                usePercentTooltip: false
                onMoved: Battery.setChargeLimit(value)
            }

            StyledText {
                text: `${Battery.chargeLimit}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
