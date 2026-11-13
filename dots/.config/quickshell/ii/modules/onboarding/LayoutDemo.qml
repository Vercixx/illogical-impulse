pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property string layout: "dwindle"
    property int frameIndex: 0
    readonly property var windowIcons: ["terminal", "folder", "edit_note", "language"]
    readonly property real gap: 6
    readonly property var frames: root.framesFor(root.layout)
    readonly property var rects: root.frames[root.frameIndex % root.frames.length]

    // Spaced so 0.6 x 0.7 windows never overlap
    readonly property var driftCenters: [
        { "x": 0, "y": 0 },
        { "x": 0.64, "y": 0.12 },
        { "x": -0.2, "y": 0.74 },
        { "x": -0.66, "y": -0.1 }
    ]
    readonly property var driftCameras: [...root.driftCenters, { "x": 0.35, "y": 0.35 }, { "x": -0.45, "y": 0.35 }]
    readonly property bool isDrift: root.layout === "lua:drift"
    readonly property var camera: root.isDrift ? root.driftCameras[root.frameIndex % root.frames.length] : { "x": 0, "y": 0 }

    function dwindle(count) {
        const rects = [];
        let free = { "x": 0, "y": 0, "w": 1, "h": 1 };
        for (let i = 0; i < count - 1; i++) {
            if (i % 2 === 0) {
                rects.push({ "x": free.x, "y": free.y, "w": free.w / 2, "h": free.h });
                free = { "x": free.x + free.w / 2, "y": free.y, "w": free.w / 2, "h": free.h };
            } else {
                rects.push({ "x": free.x, "y": free.y, "w": free.w, "h": free.h / 2 });
                free = { "x": free.x, "y": free.y + free.h / 2, "w": free.w, "h": free.h / 2 };
            }
        }
        rects.push(free);
        return rects;
    }

    function arrange(layout, count) {
        const indexes = [...Array(count).keys()];
        switch (layout) {
        case "master":
            if (count === 1)
                return [{ "x": 0, "y": 0, "w": 1, "h": 1 }];
            return indexes.map(i => i === 0 ? { "x": 0, "y": 0, "w": 0.5, "h": 1 } : { "x": 0.5, "y": (i - 1) / (count - 1), "w": 0.5, "h": 1 / (count - 1) });
        case "monocle":
            return indexes.map(i => ({ "x": 0, "y": 0, "w": 1, "h": 1 }));
        default:
            return root.dwindle(count);
        }
    }

    function framesFor(layout) {
        switch (layout) {
        case "scrolling": {
            const column = (x, y = 0, h = 1) => ({ "x": x, "y": y, "w": 0.5, "h": h });
            return [
                [{ "x": 0, "y": 0, "w": 1, "h": 1 }],
                [column(0), column(0.5)],
                [column(-0.5), column(0), column(0.5)],
                [column(-0.5), column(0, 0, 1 / 2), column(0, 1 / 2, 1 / 2)],
                [column(-0.5), column(0, 0, 1 / 2), column(0, 1 / 2, 1 / 2), column(0.5)],
                [column(-0.5), column(0, 0, 1 / 3), column(0, 1 / 3, 1 / 3), column(0, 2 / 3, 1 / 3)]
            ];
        }
        case "lua:drift":
            return root.driftCameras.map((camera, i) => root.driftCenters.slice(0, i + 1).map(center => ({
                "x": 0.2 + center.x - camera.x,
                "y": 0.15 + center.y - camera.y,
                "w": 0.6,
                "h": 0.7
            })));
        default:
            return [1, 2, 3, 4].map(count => root.arrange(layout, count));
        }
    }

    implicitWidth: 384
    implicitHeight: 216
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 1400
        onTriggered: root.frameIndex = (root.frameIndex + 1) % root.frames.length
    }

    // Spans 3x3 screens so every camera in driftCameras stays covered
    Canvas {
        id: dotGrid
        readonly property real spacing: 16
        readonly property color dotColor: Appearance.colors.colOutlineVariant
        x: -root.width - root.camera.x * (root.width - root.gap)
        y: -root.height - root.camera.y * (root.height - root.gap)
        width: root.width * 3
        height: root.height * 3
        opacity: root.isDrift ? 1 : 0
        visible: opacity > 0

        onDotColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = dotGrid.dotColor;
            ctx.beginPath();
            for (let x = dotGrid.spacing / 2; x < width; x += dotGrid.spacing) {
                for (let y = dotGrid.spacing / 2; y < height; y += dotGrid.spacing) {
                    ctx.moveTo(x, y);
                    ctx.arc(x, y, 1.5, 0, 2 * Math.PI);
                }
            }
            ctx.fill();
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on y {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Repeater {
        model: root.windowIcons
        delegate: Rectangle {
            id: demoWindow
            required property string modelData
            required property int index
            readonly property bool shown: index < root.rects.length
            readonly property var rect: root.rects[Math.min(index, root.rects.length - 1)]
            x: root.gap + rect.x * (root.width - root.gap)
            y: root.gap + rect.y * (root.height - root.gap)
            width: rect.w * (root.width - root.gap) - root.gap
            height: rect.h * (root.height - root.gap) - root.gap
            radius: Appearance.rounding.unsharpenmore
            color: Appearance.colors.colSecondaryContainer
            opacity: shown ? 1 : 0

            Behavior on x {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            Behavior on y {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            Behavior on width {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            Behavior on height {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: demoWindow.modelData
                iconSize: 28
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
    }
}
