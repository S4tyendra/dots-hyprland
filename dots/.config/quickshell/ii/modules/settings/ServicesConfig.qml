import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "neurology"
        title: Translation.tr("AI")

        GroupedList {
            ConfigTextArea {
                text: Translation.tr("System prompt")
                fieldHeight: 160
                Layout.fillWidth: true
                placeholderText: Translation.tr("System prompt")
                value: Config.options.ai.systemPrompt
                textArea.wrapMode: TextEdit.Wrap
                onValueChanged: {
                    Qt.callLater(() => {
                        Config.options.ai.systemPrompt = value;
                    });
                }
            }
        }
    }

    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

        GroupedList {
            ConfigSpinBox {
                icon: "timer_off"
                text: Translation.tr("Total duration timeout (s)")
                value: Config.options.musicRecognition.timeout
                from: 10
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.musicRecognition.timeout = value;
                }
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (s)")
                value: Config.options.musicRecognition.interval
                from: 2
                to: 10
                stepSize: 1
                onValueChanged: {
                    Config.options.musicRecognition.interval = value;
                }
            }
        }
    }

    ContentSection {
        icon: "cell_tower"
        title: Translation.tr("Networking")

        GroupedList {
            ConfigTextArea {
                text: Translation.tr("User agent")
                Layout.fillWidth: true
                placeholderText: Translation.tr("User agent (for services that require it)")
                value: Config.options.networking.userAgent
                textArea.wrapMode: TextEdit.Wrap
                onValueChanged: {
                    Config.options.networking.userAgent = value;
                }
            }
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Resources")

        GroupedList {
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (ms)")
                value: Config.options.resources.updateInterval
                from: 100
                to: 10000
                stepSize: 100
                onValueChanged: {
                    Config.options.resources.updateInterval = value;
                }
            }
        }
    }

    ContentSection {
        icon: "file_open"
        title: Translation.tr("Save paths")

        GroupedList {
            ConfigTextArea {
                text: Translation.tr("Video recording path")
                Layout.fillWidth: true
                placeholderText: Translation.tr("Video Recording Path")
                value: Config.options.screenRecord.savePath
                textArea.wrapMode: TextEdit.Wrap
                onValueChanged: {
                    Config.options.screenRecord.savePath = value;
                }
            }

            ConfigTextArea {
                text: Translation.tr("Screenshot path")
                Layout.fillWidth: true
                placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
                value: Config.options.screenSnip.savePath
                textArea.wrapMode: TextEdit.Wrap
                onValueChanged: {
                    Config.options.screenSnip.savePath = value;
                }
            }
        }
    }

    ContentSection {
        icon: "search"
        title: Translation.tr("Search")

        GroupedList {
            ConfigSwitch {
                text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                checked: Config.options.search.sloppy
                onCheckedChanged: {
                    Config.options.search.sloppy = checked;
                }
                StyledToolTip {
                    text: Translation.tr(
                              "Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Prefixes")
            GroupedList {
                ConfigTextArea {
                    text: Translation.tr("Action prefix")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Action")
                    value: Config.options.search.prefix.action
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.prefix.action = value;
                    }
                }
                ConfigTextArea {
                    text: Translation.tr("Clipboard prefix")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Clipboard")
                    value: Config.options.search.prefix.clipboard
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.prefix.clipboard = value;
                    }
                }
                ConfigTextArea {
                    text: Translation.tr("Emoji prefix")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Emojis")
                    value: Config.options.search.prefix.emojis
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.prefix.emojis = value;
                    }
                }

                ConfigTextArea {
                    text: Translation.tr("Math prefix")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Math")
                    value: Config.options.search.prefix.math
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.prefix.math = value;
                    }
                }
                ConfigTextArea {
                    text: Translation.tr("Shell command prefix")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Shell command")
                    value: Config.options.search.prefix.shellCommand
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.prefix.shellCommand = value;
                    }
                }
                ConfigTextArea {
                    text: Translation.tr("Web search prefix")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Web search")
                    value: Config.options.search.prefix.webSearch
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.prefix.webSearch = value;
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Web search")
            GroupedList {
                ConfigTextArea {
                    text: Translation.tr("Base URL")
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Base URL")
                    value: Config.options.search.engineBaseUrl
                    textArea.wrapMode: TextEdit.Wrap
                    onValueChanged: {
                        Config.options.search.engineBaseUrl = value;
                    }
                }
            }
        }
    }

    // There's no update indicator in ii for now so we shouldn't show this yet
    // ContentSection {
    //     icon: "deployed_code_update"
    //     title: Translation.tr("System updates (Arch only)")

    //     ConfigSwitch {
    //         text: Translation.tr("Enable update checks")
    //         checked: Config.options.updates.enableCheck
    //         onCheckedChanged: {
    //             Config.options.updates.enableCheck = checked;
    //         }
    //     }

    //     ConfigSpinBox {
    //         icon: "av_timer"
    //         text: Translation.tr("Check interval (mins)")
    //         value: Config.options.updates.checkInterval
    //         from: 60
    //         to: 1440
    //         stepSize: 60
    //         onValueChanged: {
    //             Config.options.updates.checkInterval = value;
    //         }
    //     }
    // }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "assistant_navigation"
                text: Translation.tr("Enable GPS based location")
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "thermometer"
                text: Translation.tr("Fahrenheit unit")
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }
                StyledToolTip {
                    text: Translation.tr("It may take a few seconds to update")
                }
            }

            CitySearchField {
                Layout.fillWidth: true
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (m)")
                value: Config.options.bar.weather.fetchInterval
                from: 5
                to: 50
                stepSize: 5
                onValueChanged: {
                    Config.options.bar.weather.fetchInterval = value;
                }
            }
            ConfigTextArea {
                text: Translation.tr("Weather API key")
                Layout.fillWidth: true
                placeholderText: Translation.tr("API Key (weather.com)")
                value: Config.options.bar.weather.apiKey
                textArea.wrapMode: TextEdit.Wrap
                onValueChanged: {
                    Qt.callLater(() => {
                        Config.options.bar.weather.apiKey = value;
                    });
                }
            }
        }
    }
}
