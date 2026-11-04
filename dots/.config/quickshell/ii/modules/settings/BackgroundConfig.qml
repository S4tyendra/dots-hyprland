import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "movie"
        title: Translation.tr("Live wallpapers")
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr(
                      "Choose a local MP4, WebM, MKV, AVI or MOV in the wallpaper picker. Playback is muted, prefers hardware decoding, and pauses while locked, the display is off, or a fullscreen window covers the display. Normal tiled windows keep the wallpaper playing.")
            wrapMode: Text.Wrap
        }
        GroupedList {
            ConfigSwitch {
                text: Translation.tr("Pause on battery")
                buttonIcon: "battery_saver"
                checked: Config.options.background.liveWallpaper.pauseOnBattery
                onCheckedChanged: Config.options.background.liveWallpaper.pauseOnBattery = checked
            }
            ConfigSpinBox {
                text: Translation.tr("Pause below battery (%)")
                value: Config.options.background.liveWallpaper.pauseBelowPercent
                from: 0
                to: 100
                onValueChanged: Config.options.background.liveWallpaper.pauseBelowPercent = value
            }
            ConfigSpinBox {
                text: Translation.tr("Maximum frames per second")
                value: Config.options.background.liveWallpaper.maxFps
                from: 10
                to: 30
                onValueChanged: Config.options.background.liveWallpaper.maxFps = value
            }
        }
        RippleButtonWithIcon {
            materialIcon: LiveWallpaper.manuallyPaused ? "play_arrow" : "pause"
            mainText: LiveWallpaper.manuallyPaused ? Translation.tr("Resume wallpaper") : Translation.tr(
                                                         "Pause wallpaper")
            enabled: LiveWallpaper.available
            onClicked: LiveWallpaper.toggle()
        }
        StyledText {
            Layout.fillWidth: true
            visible: LiveWallpaper.available || LiveWallpaper.error !== ""
            text: LiveWallpaper.error || (LiveWallpaper.pauseReasons.length > 0 ? [...new Set(
                                                                                       LiveWallpaper.pauseReasons)].join(
                                                                                      " · ") : Translation.tr(
                                                                                      "Wallpaper is playing"))
            color: LiveWallpaper.error ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }

    ContentSection {
        icon: "sync_alt"
        title: Translation.tr("Parallax")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "unfold_more_double"
                text: Translation.tr("Vertical")
                checked: Config.options.background.parallax.vertical
                onCheckedChanged: {
                    Config.options.background.parallax.vertical = checked;
                }
            }
        }

        ColumnLayout {

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "counter_1"
                    text: Translation.tr("Depends on workspace")
                    checked: Config.options.background.parallax.enableWorkspace
                    onCheckedChanged: {
                        Config.options.background.parallax.enableWorkspace = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "side_navigation"
                    text: Translation.tr("Depends on sidebars")
                    checked: Config.options.background.parallax.enableSidebar
                    onCheckedChanged: {
                        Config.options.background.parallax.enableSidebar = checked;
                    }
                }
            }
        }
        GroupedList {
            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Preferred wallpaper zoom (%)")
                value: Config.options.background.parallax.workspaceZoom * 100
                from: 10
                to: 200
                stepSize: 1
                onValueChanged: {
                    Config.options.background.parallax.workspaceZoom = value / 100;
                }
            }
        }
    }

    ContentSection {
        icon: "auto_awesome"
        title: Translation.tr("Wallpaper Switching Animation")

        ContentSubsection {
            title: Translation.tr("Transition Effect")
            Layout.fillWidth: true

            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.wallpaperAnimation
                    onSelected: newValue => {
                        Config.options.background.wallpaperAnimation = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Disable"),
                            icon: "block",
                            value: ""
                        },
                        {
                            displayName: Translation.tr("Random"),
                            icon: "shuffle",
                            value: "random"
                        },
                        {
                            displayName: Translation.tr("Magic"),
                            icon: "auto_awesome",
                            value: "magic"
                        },
                        {
                            displayName: Translation.tr("Stripes"),
                            icon: "texture_minus",
                            value: "stripes"
                        },
                        {
                            displayName: Translation.tr("Pixelate"),
                            icon: "grid_view",
                            value: "pixelate"
                        },
                        {
                            displayName: Translation.tr("Doom Melt"),
                            icon: "local_fire_department",
                            value: "Doom"
                        },
                        {
                            displayName: Translation.tr("Page Peel"),
                            icon: "auto_stories",
                            value: "Peel"
                        },
                        {
                            displayName: Translation.tr("Circle"),
                            icon: "radio_button_unchecked",
                            value: "circle"
                        },
                        {
                            displayName: Translation.tr("Circle Pit"),
                            icon: "lens",
                            value: "circlePit"
                        },
                        {
                            displayName: Translation.tr("Circle Select"),
                            icon: "adjust",
                            value: "circleSelect"
                        },
                        {
                            displayName: Translation.tr("Crossfade"),
                            icon: "blur_on",
                            value: "transition"
                        }
                    ]
                }
            }
        }

        GroupedList {
            ConfigSlider {
                text: Translation.tr("Animation Duration")
                textWidth: 160
                value: Config.options.background.wallpaperAnimationDuration ?? 1200
                usePercentTooltip: false
                buttonIcon: "speed"
                from: 400
                to: 2400
                stepSize: 200
                snapMode: Slider.SnapAlways
                stopIndicatorValues: [400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400]
                onValueChanged: {
                    Config.options.background.wallpaperAnimationDuration = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Easing Curve")
            Layout.fillWidth: true

            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.wallpaperAnimationEasing ?? "InOutCubic"
                    onSelected: newValue => {
                        Config.options.background.wallpaperAnimationEasing = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("InOut Cubic"),
                            icon: "animation",
                            value: "InOutCubic"
                        },
                        {
                            displayName: Translation.tr("Out Cubic"),
                            icon: "trending_up",
                            value: "OutCubic"
                        },
                        {
                            displayName: Translation.tr("InOut Quad"),
                            icon: "show_chart",
                            value: "InOutQuad"
                        },
                        {
                            displayName: Translation.tr("Linear"),
                            icon: "line_axis",
                            value: "Linear"
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        id: settingsClock
        icon: "clock_loader_40"
        title: Translation.tr("Widget: Clock")

        function stylePresent(styleName) {
            if (!Config.options.background.widgets.clock.showOnlyWhenLocked
                    && Config.options.background.widgets.clock.style === styleName) {
                return true;
            }
            if (Config.options.background.widgets.clock.styleLocked === styleName) {
                return true;
            }
            return false;
        }

        readonly property bool digitalPresent: stylePresent("digital")
        readonly property bool cookiePresent: stylePresent("cookie")

        ColumnLayout {
            Layout.fillWidth: true

            GroupedList {
                ConfigSwitch {

                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.enable = checked;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Placement")

                    currentValue: Config.options.background.widgets.clock.placementStrategy
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.placementStrategy = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
            }
        }

        GroupedList {
            ConfigSwitch {
                buttonIcon: "lock_clock"
                text: Translation.tr("Show only when locked")
                checked: Config.options.background.widgets.clock.showOnlyWhenLocked
                onCheckedChanged: {
                    Config.options.background.widgets.clock.showOnlyWhenLocked = checked;
                }
            }
        }

        ColumnLayout {
            ContentSubsection {
                visible: !Config.options.background.widgets.clock.showOnlyWhenLocked
                title: Translation.tr("Clock style")
                Layout.fillWidth: true
                GroupedList {
                    ConfigSelectionArray {
                        currentValue: Config.options.background.widgets.clock.style
                        onSelected: newValue => {
                            Config.options.background.widgets.clock.style = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Digital"),
                                icon: "timer_10",
                                value: "digital"
                            },
                            {
                                displayName: Translation.tr("Cookie"),
                                icon: "cookie",
                                value: "cookie"
                            }
                        ]
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Clock style (locked)")

                GroupedList {
                    ConfigSelectionArray {
                        currentValue: Config.options.background.widgets.clock.styleLocked
                        onSelected: newValue => {
                            Config.options.background.widgets.clock.styleLocked = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Digital"),
                                icon: "timer_10",
                                value: "digital"
                            },
                            {
                                displayName: Translation.tr("Cookie"),
                                icon: "cookie",
                                value: "cookie"
                            }
                        ]
                    }
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.digitalPresent
            title: Translation.tr("Digital clock settings")
            tooltip: Translation.tr(
                         "Font width and roundness settings are only available for some fonts like Google Sans Flex")

            ColumnLayout {

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "vertical_distribute"
                        text: Translation.tr("Vertical")
                        checked: Config.options.background.widgets.clock.digital.vertical
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.vertical = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "animation"
                        text: Translation.tr("Animate time change")
                        checked: Config.options.background.widgets.clock.digital.animateChange
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.animateChange = checked;
                        }
                    }
                }
            }

            ColumnLayout {

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "date_range"
                        text: Translation.tr("Show date")
                        checked: Config.options.background.widgets.clock.digital.showDate
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.showDate = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "activity_zone"
                        text: Translation.tr("Use adaptive alignment")
                        checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.digital.adaptiveAlignment = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr(
                                      "Aligns the date and quote to left, center or right depending on its position on the screen.")
                        }
                    }
                }
            }

            GroupedList {
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Font family")
                    text: Config.options.background.widgets.clock.digital.font.family
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.background.widgets.clock.digital.font.family = text;
                    }
                }

                ConfigSlider {
                    text: Translation.tr("Font weight")
                    value: Config.options.background.widgets.clock.digital.font.weight
                    usePercentTooltip: false
                    buttonIcon: "format_bold"
                    from: 1
                    to: 1000
                    stopIndicatorValues: [350]
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.weight = value;
                    }
                }

                ConfigSlider {
                    text: Translation.tr("Font size")
                    value: Config.options.background.widgets.clock.digital.font.size
                    usePercentTooltip: false
                    buttonIcon: "format_size"
                    from: 50
                    to: 700
                    stopIndicatorValues: [90]
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.size = value;
                    }
                }

                ConfigSlider {
                    text: Translation.tr("Font width")
                    value: Config.options.background.widgets.clock.digital.font.width
                    usePercentTooltip: false
                    buttonIcon: "fit_width"
                    from: 25
                    to: 125
                    stopIndicatorValues: [100]
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.width = value;
                    }
                }
                ConfigSlider {
                    text: Translation.tr("Font roundness")
                    value: Config.options.background.widgets.clock.digital.font.roundness
                    usePercentTooltip: false
                    buttonIcon: "line_curve"
                    from: 0
                    to: 100
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.roundness = value;
                    }
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Cookie clock settings")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "wand_stars"
                    text: Translation.tr("Auto styling with Gemini")
                    checked: Config.options.background.widgets.clock.cookie.aiStyling
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.aiStyling = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr(
                                  "Uses Gemini to categorize the wallpaper then picks a preset based on it.\nYou'll need to set Gemini API key on the left sidebar first.\nImages are downscaled for performance, but just to be safe,\ndo not select wallpapers with sensitive information.")
                    }
                }

                ConfigSwitch {
                    buttonIcon: "airwave"
                    text: Translation.tr("Use old sine wave cookie implementation")
                    checked: Config.options.background.widgets.clock.cookie.useSineCookie
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.useSineCookie = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr(
                                  "Looks a bit softer and more consistent with different number of sides,\nbut has less impressive morphing")
                    }
                }

                ConfigSpinBox {
                    icon: "add_triangle"
                    text: Translation.tr("Sides")
                    value: Config.options.background.widgets.clock.cookie.sides
                    from: 0
                    to: 40
                    stepSize: 1
                    onValueChanged: {
                        Config.options.background.widgets.clock.cookie.sides = value;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "autoplay"
                    text: Translation.tr("Constantly rotate")
                    checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr(
                                  "Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical.")
                    }
                }
            }

            ColumnLayout {

                GroupedList {
                    ConfigSwitch {
                        enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots"
                                 || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                        buttonIcon: "brightness_7"
                        text: Translation.tr("Hour marks")
                        checked: Config.options.background.widgets.clock.cookie.hourMarks
                        onEnabledChanged: {
                            checked = Config.options.background.widgets.clock.cookie.hourMarks;
                        }
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.cookie.hourMarks = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr(
                                      "Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons")
                        }
                    }

                    ConfigSwitch {
                        enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                        buttonIcon: "timer_10"
                        text: Translation.tr("Digits in the middle")
                        checked: Config.options.background.widgets.clock.cookie.timeIndicators
                        onEnabledChanged: {
                            checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                        }
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.cookie.timeIndicators = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr(
                                      "Can't be turned on when using 'Numbers' dial style for aesthetic reasons")
                        }
                    }
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Dial style")
            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
                        if (newValue !== "dots" && newValue !== "full") {
                            Config.options.background.widgets.clock.cookie.hourMarks = false;
                        }
                        if (newValue === "numbers") {
                            Config.options.background.widgets.clock.cookie.timeIndicators = false;
                        }
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "none"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "graph_6",
                            value: "dots"
                        },
                        {
                            displayName: Translation.tr("Full"),
                            icon: "history_toggle_off",
                            value: "full"
                        },
                        {
                            displayName: Translation.tr("Numbers"),
                            icon: "counter_1",
                            value: "numbers"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Hour hand")
            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Hollow"),
                            icon: "circle",
                            value: "hollow"
                        },
                        {
                            displayName: Translation.tr("Fill"),
                            icon: "eraser_size_5",
                            value: "fill"
                        },
                    ]
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Minute hand")

            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Thin"),
                            icon: "line_end",
                            value: "thin"
                        },
                        {
                            displayName: Translation.tr("Medium"),
                            icon: "eraser_size_2",
                            value: "medium"
                        },
                        {
                            displayName: Translation.tr("Bold"),
                            icon: "eraser_size_4",
                            value: "bold"
                        },
                    ]
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Second hand")

            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Line"),
                            icon: "line_end",
                            value: "line"
                        },
                        {
                            displayName: Translation.tr("Dot"),
                            icon: "adjust",
                            value: "dot"
                        },
                    ]
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Date style")

            GroupedList {
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.dateStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Bubble"),
                            icon: "bubble_chart",
                            value: "bubble"
                        },
                        {
                            displayName: Translation.tr("Border"),
                            icon: "rotate_right",
                            value: "border"
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "rectangle",
                            value: "rect"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quote")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.quote.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.quote.enable = checked;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Quote")
                    text: Config.options.background.widgets.clock.quote.text
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.background.widgets.clock.quote.text = text;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Widget: Weather")

        ColumnLayout {
            Layout.fillWidth: true

            GroupedList {
                ConfigSwitch {

                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.weather.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.weather.enable = checked;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Placement")

                    currentValue: Config.options.background.widgets.weather.placementStrategy
                    onSelected: newValue => {
                        Config.options.background.widgets.weather.placementStrategy = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
            }
        }
    }

    ContentSection {
        id: visualizerSection
        icon: "equalizer"
        title: Translation.tr("Widget: Visualizer")

        readonly property bool isWave: Config.options.background.widgets.visualizer.mode === "wave"

        ColumnLayout {
            Layout.fillWidth: true

            GroupedList {
                ConfigSwitch {

                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.visualizer.enable
                    onCheckedChanged: Config.options.background.widgets.visualizer.enable = checked
                }
            }
            ContentSubsection {
                title: Translation.tr("Visualizer style")

                visible: Config.options.background.widgets.visualizer.enable
                GroupedList {
                    ConfigSelectionArray {

                        currentValue: Config.options.background.widgets.visualizer.mode
                        onSelected: newValue => {
                            Config.options.background.widgets.visualizer.mode = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Bars"),
                                icon: "equalizer",
                                value: "bars"
                            },
                            {
                                displayName: Translation.tr("Wave"),
                                icon: "airwave",
                                value: "wave"
                            }
                        ]
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Config.options.background.widgets.visualizer.enable
            spacing: 16

            ContentSubsection {
                title: Translation.tr("Visibility")

                ColumnLayout {

                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "crop_free"
                            text: Translation.tr("Hide when fullscreen/maximized")
                            checked: Config.options.background.widgets.visualizer.hideWhenFullscreen
                            onCheckedChanged: {
                                Config.options.background.widgets.visualizer.hideWhenFullscreen = checked;
                                if (!checked) {
                                    Config.options.background.widgets.visualizer.hideWhenCovered = false;
                                }
                            }
                            StyledToolTip {
                                text: Translation.tr(
                                          "Hide the visualizer when a window is in fullscreen or maximized mode. (Recommended)")
                            }
                        }
                    }
                }

                ColumnLayout {

                    GroupedList {
                        ConfigSwitch {
                            id: hideWhenCoveredSwitch
                            buttonIcon: "lock"
                            visible: Config.options.background.widgets.visualizer.hideWhenFullscreen
                            text: Translation.tr("Also hide when covered")
                            checked: Config.options.background.widgets.visualizer.hideWhenCovered
                            onCheckedChanged: {
                                Config.options.background.widgets.visualizer.hideWhenCovered = checked;
                            }
                            StyledToolTip {
                                text: Translation.tr("Hide the visualizer when covered by tiled windows.")
                            }
                        }
                    }

                    // Ensure that "hide when covered" is visibly off when hide when fullscreen is turned off
                    Binding {
                        target: hideWhenCoveredSwitch
                        property: "checked"
                        value: Config.options.background.widgets.visualizer.hideWhenCovered
                        when: !hideWhenCoveredSwitch.pressed
                    }
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.visualizer.mode === "wave"
                title: Translation.tr("Performance mode")
                tooltip: Translation.tr("Note: Auto mode requires 'power-profiles-daemon' (Arch) package")

                GroupedList {
                    ConfigSelectionArray {
                        currentValue: Config.options.background.widgets.visualizer.renderEveryXFrames
                        onSelected: newValue => {
                            Config.options.background.widgets.visualizer.renderEveryXFrames = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Auto"),
                                icon: "auto_fix_high",
                                value: -1
                            },
                            {
                                displayName: Translation.tr("Smooth mode"),
                                icon: "speed",
                                value: 1
                            },
                            {
                                displayName: Translation.tr("Balanced mode"),
                                icon: "balance",
                                value: 2
                            },
                            {
                                displayName: Translation.tr("Efficiency mode"),
                                icon: "energy_savings_leaf",
                                value: 4
                            }
                        ]
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Behavior & Processing")

                ColumnLayout {

                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "lock"
                            text: Translation.tr("Show when locked")
                            checked: Config.options.background.widgets.visualizer.showWhenLocked
                            onCheckedChanged: {
                                Config.options.background.widgets.visualizer.showWhenLocked = checked;
                            }
                        }
                        ConfigSwitch {
                            buttonIcon: "flip"
                            text: Translation.tr("Mono / Mirrored")
                            checked: Config.options.background.widgets.visualizer.mono
                            onCheckedChanged: {
                                Config.options.background.widgets.visualizer.mono = checked;
                            }
                        }
                    }
                }

                GroupedList {
                    ConfigSlider {
                        buttonIcon: "waves"
                        text: Translation.tr("Data Averaging")
                        value: (Config.options.background.widgets.visualizer.dataSmoothing ?? 0.5) * 100
                        from: 0
                        to: 100
                        stopIndicatorValues: [50]
                        onValueChanged: {
                            Config.options.background.widgets.visualizer.dataSmoothing = value / 100;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Sizing & Resolution")

                ColumnLayout {

                    GroupedList {
                        ConfigSpinBox {
                            icon: "height"
                            text: Translation.tr("Max Height")
                            value: Config.options.background.widgets.visualizer.height
                            from: 60
                            to: 1080
                            stepSize: 10
                            onValueChanged: {
                                Config.options.background.widgets.visualizer.height = value;
                            }
                        }
                        ConfigSpinBox {
                            icon: "view_column"
                            text: visualizerSection.isWave ? Translation.tr("Point Width") : Translation.tr(
                                                                 "Bar Width")
                            value: Config.options.background.widgets.visualizer.targetBarWidth
                            from: 1
                            to: 200
                            onValueChanged: {
                                Config.options.background.widgets.visualizer.targetBarWidth = value;
                            }
                        }
                    }
                }

                ColumnLayout {

                    GroupedList {
                        ConfigSpinBox {
                            icon: "space_bar"
                            text: visualizerSection.isWave ? Translation.tr("Point Gap") : Translation.tr(
                                                                 "Bar Gap")
                            value: Config.options.background.widgets.visualizer.barSpacing
                            from: 0
                            to: 100
                            onValueChanged: {
                                Config.options.background.widgets.visualizer.barSpacing = value;
                            }
                        }
                        ConfigSpinBox {
                            icon: "line_weight"
                            text: visualizerSection.isWave ? Translation.tr("Line Thickness") : Translation.tr(
                                                                 "Border Width")
                            value: Config.options.background.widgets.visualizer.waveBorderWidth
                            from: 0
                            to: 20
                            onValueChanged: {
                                Config.options.background.widgets.visualizer.waveBorderWidth = value;
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Appearance")

                ColumnLayout {

                    GroupedList {
                        ConfigSlider {
                            buttonIcon: "opacity"
                            text: Translation.tr("Master Opacity")
                            value: Config.options.background.widgets.visualizer.opacity * 100
                            from: 0
                            to: 100
                            stopIndicatorValues: [50]
                            onValueChanged: {
                                Config.options.background.widgets.visualizer.opacity = value / 100;
                            }
                        }
                    }
                }

                ColumnLayout {

                    GroupedList {
                        ConfigSlider {
                            buttonIcon: "speed"
                            text: Translation.tr("Smoothing")
                            value: Config.options.background.widgets.visualizer.smoothing * 100
                            from: 0
                            to: 20
                            stopIndicatorValues: [5]
                            onValueChanged: {
                                Config.options.background.widgets.visualizer.smoothing = value / 100;
                            }
                        }
                    }
                }

                GroupedList {
                    ConfigSlider {
                        visible: visualizerSection.isWave
                        buttonIcon: "format_color_fill"
                        text: Translation.tr("Fill Opacity")
                        value: Config.options.background.widgets.visualizer.waveFillOpacity * 100
                        from: 0
                        to: 100
                        stopIndicatorValues: [50]
                        onValueChanged: {
                            Config.options.background.widgets.visualizer.waveFillOpacity = value / 100;
                        }
                    }

                    ConfigSlider {
                        visible: !visualizerSection.isWave
                        buttonIcon: "format_color_reset"
                        text: Translation.tr("Border Opacity")
                        value: Config.options.background.widgets.visualizer.waveFillOpacity * 100
                        from: 0
                        to: 100
                        stopIndicatorValues: [50]
                        onValueChanged: {
                            Config.options.background.widgets.visualizer.waveFillOpacity = value / 100;
                        }
                    }

                    ConfigSlider {
                        visible: !visualizerSection.isWave
                        buttonIcon: "rounded_corner"
                        text: Translation.tr("Bar Roundness")
                        value: Config.options.background.widgets.visualizer.barRounding * 100
                        from: 0
                        to: 50
                        stopIndicatorValues: [25]
                        onValueChanged: {
                            Config.options.background.widgets.visualizer.barRounding = value / 100;
                        }
                    }
                }
            }
        }
    }
}
