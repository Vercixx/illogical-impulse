pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

OnboardingPage {
    id: root
    icon: "dashboard"
    title: Translation.tr("Windows that arrange themselves")
    description: Translation.tr("Hyprland, which powers this desktop, is a tiling window manager. Instead of piling on top of each other, windows split the free space on screen, so everything is visible. Most of the actions are done using keybinds, usually with the Super key (one with Windows logo)")

    property int windowCount: 1
    readonly property var windowIcons: ["terminal", "folder", "edit_note", "language"]

    function layout(count) {
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

    Timer {
        running: true
        repeat: true
        interval: 1400
        onTriggered: root.windowCount = root.windowCount % root.windowIcons.length + 1
    }

    Rectangle {
        id: demoScreen
        readonly property real gap: 6
        readonly property var rects: root.layout(root.windowCount)
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 384
        implicitHeight: 216
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1

        Repeater {
            model: root.windowIcons
            delegate: Rectangle {
                id: demoWindow
                required property string modelData
                required property int index
                readonly property bool shown: index < root.windowCount
                readonly property var rect: demoScreen.rects[Math.min(index, root.windowCount - 1)]
                x: demoScreen.gap + rect.x * (demoScreen.width - demoScreen.gap)
                y: demoScreen.gap + rect.y * (demoScreen.height - demoScreen.gap)
                width: rect.w * (demoScreen.width - demoScreen.gap) - demoScreen.gap
                height: rect.h * (demoScreen.height - demoScreen.gap) - demoScreen.gap
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
}
