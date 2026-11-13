pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    readonly property int workspaceId: monitor?.activeWorkspace?.id ?? -1
    readonly property var windows: HyprlandData.windowList.filter(w => w.workspace.id === root.workspaceId)
    readonly property point camera: Drift.cameraFor(root.workspaceId)
    readonly property var bookmarks: Drift.bookmarksFor(root.workspaceId).map(m => ({ slot: m.slot, x: m.x - camera.x, y: m.y - camera.y }))

    readonly property rect view: Qt.rect(monitorData?.x ?? 0, monitorData?.y ?? 0, (monitorData?.width ?? 1920) / (monitorData?.scale ?? 1), (monitorData?.height ?? 1080) / (monitorData?.scale ?? 1))
    readonly property rect bounds: {
        let x1 = view.x, y1 = view.y, x2 = view.x + view.width, y2 = view.y + view.height;
        for (const w of root.windows) {
            x1 = Math.min(x1, w.at[0]);
            y1 = Math.min(y1, w.at[1]);
            x2 = Math.max(x2, w.at[0] + w.size[0]);
            y2 = Math.max(y2, w.at[1] + w.size[1]);
        }
        for (const m of root.bookmarks) {
            x1 = Math.min(x1, m.x);
            y1 = Math.min(y1, m.y);
            x2 = Math.max(x2, m.x);
            y2 = Math.max(y2, m.y);
        }
        const pad = Math.max(x2 - x1, y2 - y1) * 0.05;
        return Qt.rect(x1 - pad, y1 - pad, x2 - x1 + pad * 2, y2 - y1 + pad * 2);
    }

    readonly property real canvasWidth: screen.width * 0.7
    readonly property real canvasHeight: canvasWidth * view.height / view.width
    readonly property real canvasScale: Math.min(canvasWidth / bounds.width, canvasHeight / bounds.height)
    readonly property real offsetX: (canvasWidth - bounds.width * canvasScale) / 2
    readonly property real offsetY: (canvasHeight - bounds.height * canvasScale) / 2

    function toCanvasX(x: real): real {
        return (x - bounds.x) * canvasScale + offsetX;
    }
    function toCanvasY(y: real): real {
        return (y - bounds.y) * canvasScale + offsetY;
    }

    implicitWidth: background.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: background.implicitHeight + Appearance.sizes.elevationMargin * 2

    Component.onCompleted: HyprlandData.updateWindowList()

    // Hyprland sends no event when Drift moves windows
    Connections {
        target: Drift
        function onCamerasChanged() {
            HyprlandData.updateWindowList();
        }
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle {
        id: background
        property real padding: 10
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        implicitWidth: root.canvasWidth + padding * 2
        implicitHeight: root.canvasHeight + padding * 2
        radius: Appearance.rounding.large + padding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Rectangle {
            id: canvas
            anchors.centerIn: parent
            width: root.canvasWidth
            height: root.canvasHeight
            radius: Appearance.rounding.large
            color: Appearance.colors.colSurfaceContainerLow
            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: canvas.width
                    height: canvas.height
                    radius: canvas.radius
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    // Closing the overview destroys this item, so act first
                    Drift.lookAt((mouse.x - root.offsetX) / root.canvasScale + root.bounds.x, (mouse.y - root.offsetY) / root.canvasScale + root.bounds.y);
                    GlobalStates.overviewOpen = false;
                }
            }

            Rectangle { // Dim everything outside the screen; the border's inner edge is the rounded hole
                readonly property real thickness: canvas.width + canvas.height
                z: 2
                x: screenFrame.x - thickness
                y: screenFrame.y - thickness
                width: screenFrame.width + thickness * 2
                height: screenFrame.height + thickness * 2
                radius: screenFrame.radius + thickness
                color: "transparent"
                border.width: thickness
                border.color: Appearance.colors.colScrim
            }

            Rectangle { // Screen overlay
                id: screenFrame
                z: 3
                x: root.toCanvasX(root.view.x)
                y: root.toCanvasY(root.view.y)
                width: root.view.width * root.canvasScale
                height: root.view.height * root.canvasScale
                radius: Appearance.rounding.small
                color: "transparent"
                border.width: 1
                border.color: Appearance.m3colors.m3outline
                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: 6
                    }
                    implicitWidth: screenLabel.implicitWidth + 16
                    implicitHeight: screenLabel.implicitHeight + 6
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colSurfaceContainerHigh

                    Row {
                        id: screenLabel
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "desktop_windows"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("Screen")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }

            Repeater {
                model: root.bookmarks
                delegate: DriftBookmarkPin {
                    id: pin
                    required property var modelData
                    z: 4
                    slot: modelData.slot
                    x: Math.round(root.toCanvasX(modelData.x) - width / 2)
                    y: Math.round(root.toCanvasY(modelData.y) - height / 2)
                    color: pinArea.containsMouse ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    MouseArea {
                        id: pinArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Drift.goToBookmark(pin.slot);
                            GlobalStates.overviewOpen = false;
                        }
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: !root.monitorData ? [] : ToplevelManager.toplevels.values.filter(toplevel => HyprlandData.windowByAddress[`0x${toplevel.HyprlandToplevel?.address}`]?.workspace?.id === root.workspaceId)
                }
                delegate: OverviewWindow {
                    id: window
                    required property var modelData
                    toplevel: modelData
                    windowData: HyprlandData.windowByAddress[`0x${modelData.HyprlandToplevel.address}`]
                    monitorData: root.monitorData
                    widgetMonitor: root.monitorData
                    scale: root.canvasScale
                    x: root.toCanvasX(windowData?.at[0] ?? 0)
                    y: root.toCanvasY(windowData?.at[1] ?? 0)
                    z: windowData?.floating ? 1 : 0
                    topLeftRadius: Appearance.rounding.small
                    topRightRadius: Appearance.rounding.small
                    bottomLeftRadius: Appearance.rounding.small
                    bottomRightRadius: Appearance.rounding.small

                    Rectangle { // Focused window
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        color: "transparent"
                        border.width: 2
                        border.color: Appearance.colors.colSecondary
                        opacity: ToplevelManager.activeToplevel === window.modelData ? 1 : 0
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    MouseArea {
                        id: windowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onEntered: window.hovered = true
                        onExited: window.hovered = false
                        onPressed: window.pressed = true
                        onReleased: window.pressed = false
                        onClicked: event => {
                            const data = window.windowData;
                            if (!data)
                                return;
                            if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`hl.dsp.window.close({window = "address:${data.address}"})`);
                                return;
                            }
                            Drift.lookAt(data.at[0] + data.size[0] / 2, data.at[1] + data.size[1] / 2);
                            Hyprland.dispatch(`hl.dsp.focus({window = "address:${data.address}"})`);
                            GlobalStates.overviewOpen = false;
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: windowArea.containsMouse
                            text: `${window.windowData?.title}\n[${window.windowData?.class}]`
                        }
                    }
                }
            }
        }
    }
}
