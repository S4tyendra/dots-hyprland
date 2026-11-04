//@ pragma UseQApplication
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.settings

ShellRoot {
    id: root
    property bool failed: false
    property int step: 0
    property int attempts: 0
    property int phase: 0
    property int keybindStage: 0
    property var compactPage: null
    property var displayedPage: null
    property bool capturing: false
    readonly property var navigation: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, -1, 7, 6]
    function check(condition, message) {
        if (!condition) { failed = true; console.error("UI REGRESSION FAIL: " + message); }
    }
    function findObject(object, name) {
        const queue = [object];
        const seen = new Set();
        while (queue.length > 0) {
            const node = queue.shift();
            if (!node || seen.has(node)) continue;
            seen.add(node);
            if (node.objectName === name) return node;
            if (node.contentItem) queue.push(node.contentItem);
            if (node.children) {
                for (let i = 0; i < node.children.length; i++) queue.push(node.children[i]);
            }
        }
        return null;
    }
    SettingsOverlay { id: settings }

    Window {
        id: window
        width: 700
        height: 240
        visible: true
        color: Appearance.colors.colLayer0
        ColumnLayout {
            width: 600
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 20
            ConfigSelectionArray {
                id: positionOptions
                Layout.fillWidth: true
                text: "Bar position"
                currentValue: 0
                options: [{displayName: "Top", icon: "arrow_upward", value: 0},
                    {displayName: "Left", icon: "arrow_back", value: 1},
                    {displayName: "Bottom", icon: "arrow_downward", value: 2},
                    {displayName: "Right", icon: "arrow_forward", value: 3}]
            }
            PeripheralBatteryIndicators {
                readings: [{id: "mouse", name: "Mouse", percentage: 0.73, charging: false, icon: "mouse"},
                    {id: "headset", name: "Headset", percentage: 0.18, charging: false, icon: "headphones"}]
            }
            Item { Layout.fillHeight: true }
        }
    }
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        GlobalStates.settingsOpen = true;
    }
    function visit(object, callback) {
        const queue = [object];
        const seen = new Set();
        while (queue.length > 0) {
            const node = queue.shift();
            if (!node || seen.has(node)) continue;
            seen.add(node);
            callback(node);
            if (node.children) {
                for (let i = 0; i < node.children.length; i++) queue.push(node.children[i]);
            }
        }
    }
    function checkBounds(page, label) {
        const content = root.findObject(page, "settingsContent");
        root.check(content && content.width <= page.width + 1, label + " content exceeds viewport");
        if (!content) return;
        root.visit(page, node => {
            if (!node.visible || node.width < 1) return;
            if (/Config(Switch|SpinBox|Slider|SelectionArray|ComboBox|TextArea)_/.test(String(node))) {
                const pos = node.mapToItem(content, 0, 0);
                root.check(pos.x >= -1 && pos.x + node.width <= content.width + 1,
                    label + " control overflow: " + (node.text || String(node)) + " x=" + pos.x + " width=" + node.width + " content=" + content.width);
            }
            if (node.objectName === "selectionButtons") {
                for (const button of node.children) {
                    if (button.buttonText !== undefined)
                        root.check(button.x + button.width <= node.width + 1, label + " option overflow: " + button.buttonText);
                }
            }
        });
    }
    function capture(item, name, after) {
        root.capturing = true;
        const accepted = item.grabToImage(result => {
            result.saveToFile(Quickshell.shellPath("screenshots/" + name + ".png"));
            root.capturing = false;
            after();
        });
        if (!accepted) {
            root.check(false, "could not capture " + name);
            root.capturing = false;
            after();
        }
    }
    function advance() {
        if (root.compactPage) { root.compactPage.destroy(); root.compactPage = null; }
        if (root.displayedPage) root.displayedPage.visible = true;
        root.phase = 0;
        root.attempts = 0;
        root.step++;
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!Config.ready || root.capturing) return;
            if (root.step < root.navigation.length) {
                const index = root.navigation[root.step];
                settings.showingProfile = index < 0;
                if (index >= 0) settings.currentPage = index;
                const page = settings.pageItem(index);
                if (!page) {
                    if (++root.attempts < 40) return;
                    root.check(false, "settings page did not load: " + index);
                    root.advance();
                    return;
                }
                root.displayedPage = page;
                if (index === 2 && DisplayConfig.monitors.length === 0) {
                    DisplayConfig.monitors = [{name: "eDP-1", mode: "1920x1080@60", x: 0, y: 0, scale: 1, transform: 0, modes: ["1920x1080@60", "1920x1080@40"]}];
                    DisplayConfig.error = "";
                }
                if (root.phase === 0) {
                    if (index === 10) page.startEdit(page.entries[0]);
                    root.phase = 1; return;
                }
                const label = index < 0 ? "Profile" : settings.pages[index].name;
                if (root.phase === 1) {
                    root.check(page.enabled && page.parent.enabled && page.parent.opacity === 1, "selected settings page is disabled or dim: " + label);
                    root.checkBounds(page, label);
                    let frame = page;
                    while (frame.parent) frame = frame.parent;
                    const scroll = root.findObject(frame, "settingsNavScroll");
                    const button = root.findObject(frame, "settingsConfigButton");
                    root.check(scroll && button && scroll.y >= button.y + button.height, "sidebar overlaps Config file button");
                    root.capture(root.findObject(frame, "settingsFrame"), label + "-normal", () => { root.phase = 2; });
                    return;
                }
                if (root.phase === 2) {
                    const path = index < 0 ? Qt.resolvedUrl("modules/settings/Profile.qml") : settings.pages[index].component;
                    const component = Qt.createComponent(path);
                    root.check(component.status === Component.Ready, "compact page failed to compile: " + label + " " + component.errorString());
                    root.compactPage = component.createObject(page.parent, {width: 360, height: page.height, z: 20});
                    root.check(!!root.compactPage, "compact page failed to instantiate: " + label);
                    if (index === 10) root.compactPage.startEdit(null);
                    page.visible = false;
                    root.phase = 3;
                    return;
                }
                if (root.phase === 3) {
                    root.checkBounds(root.compactPage, label + " compact");
                    if (index === 8) {
                        const weather = settings.findSectionByTitle(root.compactPage, Translation.tr("Widget: Weather"));
                        root.check(!!weather, "Weather section missing");
                        if (weather) root.compactPage.contentY = weather.mapToItem(root.compactPage.contentItem, 0, 0).y;
                    }
                    root.phase = 4;
                    return;
                }
                root.capture(root.compactPage, label + "-compact", () => root.advance());
                return;
            }
            const binds = settings.pageItem(10);
            if (root.keybindStage === 0) {
                root.check(binds.entries.every(entry => !!entry.description), "shortcut name missing");
                root.check(binds.inferredName('hl.bind("X", hl.dsp.exec_cmd("nemo"))').includes("nemo"), "command name not inferred");
                binds.startEdit(binds.entries.find(entry => entry.combo === "SUPER + T"));
                binds.capturedCombo = "SUPER + Y";
                binds.applyRebind();
                root.keybindStage = 1;
                return;
            }
            if (binds.saving) return;
            if (root.keybindStage === 1) {
                root.check(!binds.editorOpen, "rebind did not save: " + binds.captureError);
                root.check(binds.entries.filter(entry => entry.combo === "SUPER + Y").length === 2, "rebind lost paired action");
                root.check(!binds.entries.some(entry => entry.combo === "SUPER + T"), "overridden shortcut still listed");
                const entry = binds.entries.find(entry => entry.combo === "SUPER + Y");
                if (entry) {
                    binds.startEdit(entry);
                    binds.capturedCombo = "SUPER + U";
                    binds.applyRebind();
                }
                root.keybindStage = 2;
                return;
            }
            if (root.keybindStage === 2) {
                root.check(!binds.editorOpen, "custom shortcut edit failed");
                root.check(binds.entries.some(entry => entry.combo === "SUPER + U"), "custom rebind missing");
                binds.startEdit(null);
                root.findObject(binds, "keybindName").value = 'Launch "test"';
                root.findObject(binds, "keybindCommand").value = 'printf "hello"';
                binds.capturedCombo = "SUPER + I";
                binds.applyRebind();
                root.keybindStage = 3;
                return;
            }
            root.check(!binds.editorOpen, "new shortcut did not save: " + binds.captureError);
            root.check(binds.entries.some(entry => entry.combo === "SUPER + I" && entry.description === 'Launch "test"'), "new shortcut name missing or escaped incorrectly");
            binds.startEdit(null);
            root.check(binds.comboError("SUPER + I") !== "", "duplicate shortcut accepted");
            root.check(binds.comboError('SUPER + T"') !== "", "unsafe shortcut accepted");
            binds.closeDialog();
            stop();

            const monitor = {id: 0, width: 1920, height: 1080, scale: 1, dpmsStatus: true, activeWorkspace: {id: 1}};
            const tiled = {monitor: 0, workspace: {id: 1}, floating: false, hidden: false, fullscreen: 0, size: [1880, 990]};
            root.check(!LiveWallpaper.monitorCovered(monitor, [tiled]), "ordinary tiled window pauses live wallpaper");
            root.check(LiveWallpaper.monitorCovered(monitor, [Object.assign({}, tiled, {fullscreen: 2})]), "fullscreen window does not pause wallpaper");
            root.check(!LiveWallpaper.monitorCovered(monitor, [Object.assign({}, tiled, {fullscreen: 2, workspace: {id: 2}})]), "inactive workspace pauses wallpaper");
            root.check(LiveWallpaper.monitorCovered(Object.assign({}, monitor, {dpmsStatus: false}), []), "powered-off display does not pause wallpaper");
            const preview = LiveWallpaper.previewPath("/tmp/example.MP4");
            root.check(preview.endsWith(Qt.md5("/tmp/example.MP4") + ".jpg"), "video preview does not use its thumbnail");
            root.check(LiveWallpaper.previewPath("/tmp/photo.jpg") === "/tmp/photo.jpg", "image preview path changed");

            const power = {nativePath: "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF", model: "Mouse", percentage: 0.7, state: UPowerDeviceState.Discharging, type: UPowerDeviceType.Mouse};
            const bt = {address: "AA:BB:CC:DD:EE:FF", name: "Mouse", connected: true, batteryAvailable: true, battery: 0.72, icon: "input-mouse"};
            const readings = PeripheralBattery.readings([power], [bt]);
            root.check(readings.length === 1 && readings[0].percentage === 0.72, "Bluetooth/UPower readings duplicate a device");
            root.check(PeripheralBattery.readings([], [Object.assign({}, bt, {batteryAvailable: false})]).length === 0, "unreported device battery is shown as zero");
            root.check(PeripheralBattery.readings([power], []).length === 1, "UPower-only device indicator missing");

            const flow = root.findObject(positionOptions, "selectionButtons");
            const buttons = Array.from(flow.children).filter(child => child.buttonText !== undefined);
            root.check(buttons.length === 4 && buttons.every(button => button.y === buttons[0].y), "bar position buttons stack vertically at desktop width");
            window.contentItem.grabToImage(result => result.saveToFile(Quickshell.shellPath("regression.png")));
            console.log(root.failed ? "UI REGRESSIONS FAILED" : "UI REGRESSIONS PASS");
            done.start();
        }
    }
    Timer { id: done; interval: 200; onTriggered: Qt.quit() }
    Timer {
        interval: 45000
        running: true
        onTriggered: { root.check(false, "test timed out at navigation step " + root.step); Qt.quit(); }
    }
}
