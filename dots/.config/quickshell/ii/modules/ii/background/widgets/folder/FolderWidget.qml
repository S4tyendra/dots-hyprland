pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.worldclock

AbstractBackgroundWidget {
    id: root

    required property var folder
    folderEntry: folder
    nested: false

    property bool expanded: false
    readonly property string folderId: folder?.id ?? ""
    readonly property string folderName: folder?.name ?? Translation.tr("Folder")
    readonly property string coverKey: folder?.cover ?? ""
    readonly property var childKeys: folder?.children ?? []
    readonly property string folderIcon: folder?.icon ?? "folder"

    implicitWidth: coverHost.implicitWidth
    implicitHeight: coverHost.implicitHeight
    z: expanded ? 30 : 1
    draggable: !expanded && !nested && placementStrategy === "free" && !Config.options.background.widgetsLocked

    onVisibleChanged: if (!visible) expanded = false
    onExpandedChanged: if (expanded) Qt.callLater(sheet.reposition)

    function persistFolderPatch(patch) {
        const folders = JSON.parse(JSON.stringify(Config.options.background.widgets.folders ?? []));
        for (let i = 0; i < folders.length; i++) {
            if (folders[i].id === root.folderId) {
                Object.assign(folders[i], patch);
                break;
            }
        }
        Config.options.background.widgets.folders = folders;
    }

    onReleased: {
        const canvas = root.findCanvas(root.parent);
        if (canvas)
            canvas.setDragging(false);
        if (root.nested)
            return;
        const prevX = root.folder?.x ?? 0;
        const prevY = root.folder?.y ?? 0;
        if (Math.abs(prevX - root.x) < 1 && Math.abs(prevY - root.y) < 1)
            return;
        persistFolderPatch({
            x: root.x,
            y: root.y
        });
    }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            Config.options.background.widgetsLocked = !Config.options.background.widgetsLocked;
            return;
        }
        if (mouse.button === Qt.LeftButton)
            root.expanded = !root.expanded;
    }

    Item {
        id: coverHost
        implicitWidth: coverLoader.item ? coverLoader.item.implicitWidth : fallbackCover.implicitWidth
        implicitHeight: coverLoader.item ? coverLoader.item.implicitHeight : fallbackCover.implicitHeight
        opacity: 1

        Loader {
            id: coverLoader
            anchors.centerIn: parent
            active: root.coverKey.length > 0
            sourceComponent: catalog.componentFor(root.coverKey)
        }

        MaterialShape {
            id: fallbackCover
            visible: !coverLoader.active
            anchors.centerIn: parent
            shape: MaterialShape.Shape.Cookie9Sided
            color: Appearance.colors.colPrimaryContainer
            implicitSize: 120
            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 56
                text: root.folderIcon
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
    }

    MouseArea {
        id: dimmer
        parent: root.findCanvas(root.parent) || root
        anchors.fill: parent
        visible: root.expanded
        z: 28
        hoverEnabled: true
        onClicked: root.expanded = false
        Rectangle {
            anchors.fill: parent
            color: ColorUtils.transparentize(Appearance.colors.colShadow, 0.72)
        }
    }

    Item {
        id: sheet
        parent: root.findCanvas(root.parent) || root
        visible: opacity > 0
        z: 29
        width: body.width * body.scale
        height: body.height * body.scale
        x: placedX
        y: placedY

        property real placedX: 0
        property real placedY: 0
        property real gap: 24
        property real margin: 16
        property real flowMaxW: 99999
        property real bodyW: 0
        property real bodyH: 0
        property bool layingOut: false

        opacity: root.expanded ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        function childSizes() {
            const sizes = [];
            for (let i = 0; i < childRepeater.count; i++) {
                const loader = childRepeater.itemAt(i);
                const item = loader?.item;
                if (!item)
                    continue;
                sizes.push({
                    w: Math.max(1, item.implicitWidth || item.width),
                    h: Math.max(1, item.implicitHeight || item.height)
                });
            }
            return sizes;
        }

        function measureFlow(sizes, maxW, spacing) {
            let x = 0;
            let y = 0;
            let rowH = 0;
            let usedW = 0;
            for (let i = 0; i < sizes.length; i++) {
                const s = sizes[i];
                if (x > 0 && x + s.w > maxW) {
                    y += rowH + spacing;
                    x = 0;
                    rowH = 0;
                }
                usedW = Math.max(usedW, x + s.w);
                x += s.w + spacing;
                rowH = Math.max(rowH, s.h);
            }
            return {
                w: sizes.length ? usedW : 0,
                h: sizes.length ? y + rowH : 0
            };
        }

        function alignInRegion(region, boxW, boxH, fx, fy) {
            let px = region.x;
            let py = region.y;
            if (region.side === "right") {
                px = region.x;
                py = Math.max(region.y, Math.min(fy, region.y + region.h - boxH));
            } else if (region.side === "left") {
                px = region.x + region.w - boxW;
                py = Math.max(region.y, Math.min(fy, region.y + region.h - boxH));
            } else if (region.side === "bottom") {
                py = region.y;
                px = Math.max(region.x, Math.min(fx, region.x + region.w - boxW));
            } else if (region.side === "top") {
                py = region.y + region.h - boxH;
                px = Math.max(region.x, Math.min(fx, region.x + region.w - boxW));
            }
            return { x: px, y: py };
        }

        function reposition() {
            if (sheet.layingOut)
                return;
            const canvas = root.findCanvas(root.parent);
            if (!canvas || !root.expanded)
                return;

            const margin = sheet.margin;
            const gap = sheet.gap;
            const fx = root.x;
            const fy = root.y;
            const fw = root.width;
            const fh = root.height;
            const cw = canvas.width;
            const ch = canvas.height;
            const headerH = headerRow.implicitHeight + 14;
            const padX = 24;
            const padY = 16;
            const spacing = childFlow.spacing;
            const sizes = sheet.childSizes();

            const regions = [
                { side: "right", x: fx + fw + gap, y: margin, w: cw - (fx + fw + gap) - margin, h: ch - margin * 2 },
                { side: "left", x: margin, y: margin, w: fx - gap - margin, h: ch - margin * 2 },
                { side: "bottom", x: margin, y: fy + fh + gap, w: cw - margin * 2, h: ch - (fy + fh + gap) - margin },
                { side: "top", x: margin, y: margin, w: cw - margin * 2, h: fy - gap - margin }
            ].filter(r => r.w > 0 && r.h > 0);

            const screenRegion = { side: "screen", x: margin, y: margin, w: cw - margin * 2, h: ch - margin * 2 };
            if (regions.length === 0)
                regions.push(screenRegion);

            const oneRow = sheet.measureFlow(sizes, 1e9, spacing);
            const naturalW = Math.max(headerRow.implicitWidth, oneRow.w) + padX;
            const naturalH = oneRow.h + headerH + padY;

            let chosen = null;
            for (let i = 0; i < regions.length; i++) {
                const r = regions[i];
                if (naturalW <= r.w && naturalH <= r.h) {
                    chosen = { region: r, flowW: oneRow.w, boxW: naturalW, boxH: naturalH, scale: 1 };
                    break;
                }
            }

            if (!chosen) {
                let best = null;
                for (let i = 0; i < regions.length; i++) {
                    const r = regions[i];
                    const flow = sheet.measureFlow(sizes, Math.max(1, r.w - padX), spacing);
                    const boxW = Math.min(r.w, Math.max(headerRow.implicitWidth, flow.w) + padX);
                    const boxH = flow.h + headerH + padY;
                    if (boxH <= r.h) {
                        const leftover = (r.w - boxW) + (r.h - boxH);
                        if (!best || leftover > best.leftover)
                            best = { region: r, flowW: Math.max(1, flow.w), boxW, boxH, scale: 1, leftover };
                    }
                }
                chosen = best;
            }

            if (!chosen) {
                let region = regions[0];
                let area = region.w * region.h;
                for (let i = 1; i < regions.length; i++) {
                    const a = regions[i].w * regions[i].h;
                    if (a > area) {
                        area = a;
                        region = regions[i];
                    }
                }
                const flow = sheet.measureFlow(sizes, Math.max(1, region.w - padX), spacing);
                const boxW = Math.max(headerRow.implicitWidth, flow.w) + padX;
                const boxH = flow.h + headerH + padY;
                const scale = Math.min(1, region.w / boxW, region.h / boxH);
                chosen = {
                    region,
                    flowW: Math.max(1, flow.w),
                    boxW,
                    boxH,
                    scale
                };
            }

            const pos = sheet.alignInRegion(chosen.region, chosen.boxW * chosen.scale, chosen.boxH * chosen.scale, fx, fy);
            sheet.layingOut = true;
            sheet.flowMaxW = chosen.flowW;
            sheet.bodyW = chosen.boxW;
            sheet.bodyH = chosen.boxH;
            body.scale = chosen.scale;
            sheet.placedX = Math.max(margin, Math.min(pos.x, cw - chosen.boxW * chosen.scale - margin));
            sheet.placedY = Math.max(margin, Math.min(pos.y, ch - chosen.boxH * chosen.scale - margin));
            sheet.layingOut = false;
        }

        Connections {
            target: root
            function onXChanged() { if (root.expanded) sheet.reposition(); }
            function onYChanged() { if (root.expanded) sheet.reposition(); }
            function onWidthChanged() { if (root.expanded) sheet.reposition(); }
            function onHeightChanged() { if (root.expanded) sheet.reposition(); }
        }

        Item {
            id: body
            width: sheet.bodyW
            height: sheet.bodyH
            scale: 1
            transformOrigin: Item.TopLeft

            StyledRectangularShadow {
                target: sheetFrame
            }

            Rectangle {
                id: sheetFrame
                anchors.fill: parent
                radius: Appearance.rounding.verylarge
                color: "transparent"
                border.width: 0
                clip: true

                PreBlurredBackground {
                    anchors.fill: parent
                    cornerRadius: sheetFrame.radius
                    tintColor: Appearance.colors.colLayer0
                    tintOpacity: 0.42
                    screenW: root.screenWidth
                    screenH: root.screenHeight
                    panelX: {
                        const win = sheet.Window.window;
                        if (!win)
                            return sheet.x;
                        return sheet.mapToItem(win.contentItem, 0, 0).x;
                    }
                    panelY: {
                        const win = sheet.Window.window;
                        if (!win)
                            return sheet.y;
                        return sheet.mapToItem(win.contentItem, 0, 0).y;
                    }
                }
            }

            Column {
                id: sheetInner
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.topMargin: 10
                spacing: 10

                RowLayout {
                    id: headerRow
                    width: Math.max(childFlow.implicitWidth, 1)
                    MaterialSymbol {
                        text: root.folderIcon
                        iconSize: 22
                        color: Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.folderName
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer0
                    }
                    RippleButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        onClicked: root.expanded = false
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }

                Flow {
                    id: childFlow
                    spacing: 12
                    width: sheet.flowMaxW

                    Repeater {
                        id: childRepeater
                        model: root.expanded ? root.childKeys : []
                        delegate: Loader {
                            required property string modelData
                            active: root.expanded && modelData !== root.coverKey
                            sourceComponent: catalog.componentFor(modelData)
                            onLoaded: Qt.callLater(sheet.reposition)
                        }
                    }
                    onImplicitHeightChanged: if (root.expanded && !sheet.layingOut) Qt.callLater(sheet.reposition)
                }
            }
        }
    }

    QtObject {
        id: catalog
        function componentFor(key) {
            switch (key) {
            case "clock":
                return clockComp;
            case "weather":
                return weatherComp;
            case "media":
                return mediaComp;
            case "resources":
                return resourcesComp;
            case "userCard":
                return userCardComp;
            case "calendar":
                return calendarComp;
            case "customImage":
                return customImageComp;
            case "images":
                return imagesComp;
            case "worldClock":
                return worldClockComp;
            default:
                return null;
            }
        }
        property Component clockComp: ClockWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component weatherComp: WeatherWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component mediaComp: MediaWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component resourcesComp: ResourcesWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component userCardComp: UserCardWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component calendarComp: CalendarWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component customImageComp: CustomImage {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component imagesComp: ImageConverterWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
        property Component worldClockComp: WorldClockWidget {
            nested: true
            screenWidth: root.screenWidth
            screenHeight: root.screenHeight
            scaledScreenWidth: root.scaledScreenWidth
            scaledScreenHeight: root.scaledScreenHeight
            wallpaperScale: root.wallpaperScale
        }
    }
}
