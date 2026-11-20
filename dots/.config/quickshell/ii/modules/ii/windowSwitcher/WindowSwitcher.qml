pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Alt+Tab: cycles windows in most recently used order and focuses the pick when Alt is released
Scope {
    id: root

    property bool active: false
    property bool shown: false
    property var windows: []
    property int index: 0
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    function step(delta: int) {
        if (!root.active) {
            const list = HyprlandData.windowList
                .filter(w => !w.workspace.name.startsWith("special:"))
                .sort((a, b) => a.focusHistoryID - b.focusHistoryID);
            if (list.length === 0)
                return;
            root.windows = list;
            root.index = 0;
            root.active = true;
            showDelay.restart();
        }
        root.index = (root.index + delta + root.windows.length) % root.windows.length;
    }

    function commit() {
        if (!root.active)
            return;
        const picked = root.windows[root.index];
        root.close();
        if (picked)
            HyprlandData.focusWindow(picked.address);
    }

    function close() {
        showDelay.stop();
        root.active = false;
        root.shown = false;
    }

    function toplevelFor(address: string): var {
        return ToplevelManager.toplevels.values.find(t => `0x${t.HyprlandToplevel?.address}` === address) ?? null;
    }

    // A quick Alt+Tab switches without flashing the list
    Timer {
        id: showDelay
        interval: 150
        onTriggered: root.shown = true
    }

    GlobalShortcut {
        name: "windowSwitcherNext"
        description: "Alt+Tab: select the next window"
        onPressed: root.step(1)
    }
    GlobalShortcut {
        name: "windowSwitcherPrev"
        description: "Alt+Shift+Tab: select the previous window"
        onPressed: root.step(-1)
    }
    GlobalShortcut {
        name: "windowSwitcherRelease"
        description: "Focuses the selected window when Alt is released"
        onReleased: root.commit()
    }
    GlobalShortcut {
        name: "windowSwitcherCancel"
        description: "Closes the window switcher without switching"
        onPressed: root.close()
    }

    Loader {
        active: root.shown

        sourceComponent: PanelWindow {
            id: window
            screen: root.focusedScreen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:windowSwitcher"
            WlrLayershell.layer: WlrLayer.Overlay
            implicitWidth: background.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: background.height + Appearance.sizes.elevationMargin * 2

            StyledRectangularShadow {
                target: background
            }
            Rectangle {
                id: background
                property bool appeared: false
                anchors.centerIn: parent
                width: Math.min(list.contentWidth, (window.screen?.width ?? 1920) * 0.85) + list.padding * 2
                height: list.height + list.padding * 2
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer0
                border.color: Appearance.colors.colLayer0Border
                border.width: 1
                opacity: appeared ? 1 : 0
                scale: appeared ? 1 : 0.94
                Component.onCompleted: Qt.callLater(() => background.appeared = true)
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on scale {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                ListView {
                    id: list
                    readonly property real padding: 12
                    x: padding
                    y: padding
                    width: parent.width - padding * 2
                    height: 180
                    orientation: ListView.Horizontal
                    spacing: 8
                    clip: true
                    model: root.windows
                    currentIndex: root.index
                    highlightMoveDuration: Appearance.animation.elementMoveFast.duration
                    highlight: Rectangle {
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colSecondaryContainer
                    }

                    delegate: Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property var toplevel: root.toplevelFor(modelData.address)
                        width: 200
                        height: list.height

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.index = card.index;
                                root.commit();
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                StyledImage {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    source: Quickshell.iconPath(AppSearch.guessIcon(card.modelData.class), "image-missing")
                                    mipmap: true
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: card.modelData.title
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: card.ListView.isCurrentItem ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ScreencopyView {
                                    anchors.centerIn: parent
                                    readonly property real ratio: card.modelData.size[0] / Math.max(1, card.modelData.size[1])
                                    width: Math.min(parent.width, parent.height * ratio)
                                    height: width / ratio
                                    captureSource: card.toplevel
                                    live: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
