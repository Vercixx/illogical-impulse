pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: bar
    property bool repositioning: false

    // Anchor swaps on a live layer surface leave stale sizes, so rebuild the window instead
    Connections {
        target: Config.options.bar
        function onVerticalChanged() {
            bar.reposition();
        }
        function onBottomChanged() {
            bar.reposition();
        }
    }
    function reposition() {
        bar.repositioning = true;
        Qt.callLater(() => bar.repositioning = false);
    }

    Variants {
        // For each monitor
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked && !bar.repositioning
            required property ShellScreen modelData
            component: PanelWindow { // Bar window
                id: barRoot
                screen: barLoader.modelData

                readonly property bool vertical: Config.options.bar.vertical
                readonly property bool atEnd: Config.options.bar.bottom // Bottom or right
                readonly property real thickness: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
                readonly property real baseThickness: vertical ? Appearance.sizes.baseVerticalBarWidth : Appearance.sizes.baseBarHeight
                readonly property int deadPixel: Config.options.interactions.deadPixelWorkaround.enable ? 1 : 0
                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow || activeDrawer !== null
                property Item activeDrawer: null
                readonly property Item drawerLayer: drawerLayerItem
                readonly property var drawerWindow: drawerWindow
                readonly property bool hidden: Config.options.bar.autoHide.enable && !mustShow

                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: {
                        barRoot.superShow = true
                    }
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 :
                    baseThickness + (Appearance.barStyle.floating ? Appearance.sizes.hyprlandGapsOut : 0)
                WlrLayershell.namespace: "quickshell:bar"
                implicitWidth: thickness + Appearance.rounding.screenRounding
                implicitHeight: thickness + Appearance.rounding.screenRounding
                mask: Region {
                    item: hoverMaskRegion
                }
                color: "transparent"

                anchors {
                    top: barRoot.vertical || !barRoot.atEnd
                    bottom: barRoot.vertical || barRoot.atEnd
                    left: !barRoot.vertical || !barRoot.atEnd
                    right: !barRoot.vertical || barRoot.atEnd
                }

                margins {
                    right: -barRoot.deadPixel * barRoot.anchors.right
                    bottom: -barRoot.deadPixel * barRoot.anchors.bottom
                }

                // Drawers live on their own fixed-size surface: resizing the bar window makes it jump for a frame
                PanelWindow {
                    id: drawerWindow
                    screen: barRoot.screen
                    visible: barRoot.activeDrawer !== null
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    exclusiveZone: 0
                    WlrLayershell.namespace: "quickshell:barDrawer"
                    readonly property real depth: Math.round((barRoot.vertical ? screen.width : screen.height) * 0.75)
                    implicitWidth: depth
                    implicitHeight: depth
                    anchors {
                        top: barRoot.anchors.top
                        bottom: barRoot.anchors.bottom
                        left: barRoot.anchors.left
                        right: barRoot.anchors.right
                    }
                    margins {
                        right: barRoot.margins.right
                        bottom: barRoot.margins.bottom
                    }
                    mask: Region {
                        item: barRoot.activeDrawer?.cardItem ?? null
                    }

                    Item { // Same origin and size as the bar window, so bar window coordinates work here
                        id: drawerLayerItem
                        x: barRoot.vertical && barRoot.atEnd ? drawerWindow.width - barRoot.width : 0
                        y: !barRoot.vertical && barRoot.atEnd ? drawerWindow.height - barRoot.height : 0
                        width: barRoot.width
                        height: barRoot.height
                    }
                }

                // Include in focus grab
                Component.onCompleted: {
                    GlobalFocusGrab.addPersistent(barRoot);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(barRoot);
                }

                MouseArea  {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors {
                        fill: parent
                        rightMargin: barRoot.deadPixel * barRoot.anchors.right
                        bottomMargin: barRoot.deadPixel * barRoot.anchors.bottom
                    }

                    Item {
                        id: hoverMaskRegion
                        readonly property real extra: Config.options.bar.autoHide.hoverRegionWidth
                        anchors {
                            fill: barContent
                            topMargin: barRoot.vertical ? 0 : -extra
                            bottomMargin: barRoot.vertical ? 0 : -extra
                            leftMargin: barRoot.vertical ? -extra : 0
                            rightMargin: barRoot.vertical ? -extra : 0
                        }
                    }

                    BarContent {
                        id: barContent
                        z: 1
                        readonly property real hideOffset: barRoot.hidden ? -barRoot.thickness : 0

                        implicitWidth: Appearance.sizes.verticalBarWidth
                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            left: (!barRoot.vertical || !barRoot.atEnd) ? parent.left : undefined
                            right: (!barRoot.vertical || barRoot.atEnd) ? parent.right : undefined
                            top: (barRoot.vertical || !barRoot.atEnd) ? parent.top : undefined
                            bottom: (barRoot.vertical || barRoot.atEnd) ? parent.bottom : undefined
                            leftMargin: (barRoot.vertical && !barRoot.atEnd) ? hideOffset : 0
                            topMargin: (!barRoot.vertical && !barRoot.atEnd) ? hideOffset : 0
                            rightMargin: (barRoot.vertical && barRoot.atEnd) ? hideOffset : -barRoot.deadPixel * barRoot.anchors.right
                            bottomMargin: (!barRoot.vertical && barRoot.atEnd) ? hideOffset : -barRoot.deadPixel * barRoot.anchors.bottom
                        }
                        Behavior on anchors.leftMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    // Round decorators
                    Loader {
                        id: roundDecorators
                        active: Appearance.barStyle.strip && Appearance.barStyle.hugCorners
                        anchors {
                            left: barRoot.vertical ? (barRoot.atEnd ? undefined : barContent.right) : parent.left
                            right: barRoot.vertical ? (barRoot.atEnd ? barContent.left : undefined) : parent.right
                            top: barRoot.vertical ? parent.top : (barRoot.atEnd ? undefined : barContent.bottom)
                            bottom: barRoot.vertical ? parent.bottom : (barRoot.atEnd ? barContent.top : undefined)
                        }
                        width: Appearance.rounding.screenRounding
                        height: Appearance.rounding.screenRounding

                        sourceComponent: Item {
                            RoundCorner {
                                implicitSize: Appearance.rounding.screenRounding
                                color: Appearance.colors.colLayer0Base
                                corner: barRoot.vertical
                                    ? (barRoot.atEnd ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.TopLeft)
                                    : (barRoot.atEnd ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft)
                            }
                            RoundCorner {
                                implicitSize: Appearance.rounding.screenRounding
                                color: Appearance.colors.colLayer0Base
                                x: barRoot.vertical ? 0 : parent.width - implicitSize
                                y: barRoot.vertical ? parent.height - implicitSize : 0
                                corner: barRoot.vertical
                                    ? (barRoot.atEnd ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.BottomLeft)
                                    : (barRoot.atEnd ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight)
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
