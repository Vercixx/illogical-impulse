pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property MprisPlayer fullscreenPlayer: null
    property ShellScreen fullscreenScreen: null

    function closeFullscreen() {
        root.fullscreenPlayer = null;
        root.fullscreenScreen = null;
    }

    function focusedMediaDrawer() {
        return GlobalStates.mediaDrawers.find(drawer => drawer.hosted && drawer.host?.visible && drawer.barWindow?.screen?.name === Hyprland.focusedMonitor?.name) ?? null;
    }

    function toggle() {
        if (root.fullscreenPlayer) {
            root.closeFullscreen();
            return;
        }
        const drawer = root.focusedMediaDrawer();
        if (!drawer) {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            return;
        }
        GlobalStates.mediaControlsOpen = false;
        drawer.toggle();
    }

    function open() {
        if (root.fullscreenPlayer)
            return;
        const drawer = root.focusedMediaDrawer();
        if (!drawer) {
            GlobalStates.mediaControlsOpen = true;
            return;
        }
        GlobalStates.mediaControlsOpen = false;
        drawer.pinned = true;
    }

    function close() {
        root.closeFullscreen();
        GlobalStates.mediaControlsOpen = false;
        GlobalStates.mediaDrawers.filter(drawer => drawer.pinned).forEach(drawer => drawer.dismiss());
    }

    Connections {
        target: GlobalStates

        function onMediaFullscreenRequested(player, screen) {
            if (!player || !screen || GlobalStates.screenLocked)
                return;
            root.close();
            root.fullscreenScreen = screen;
            root.fullscreenPlayer = player;
        }

        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked)
                root.closeFullscreen();
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (!Quickshell.screens.includes(root.fullscreenScreen))
                root.closeFullscreen();
        }
    }

    Loader {
        active: root.fullscreenPlayer !== null && root.fullscreenScreen !== null
        sourceComponent: FullscreenPlayer {
            player: root.fullscreenPlayer
            screen: root.fullscreenScreen
            onDismissRequested: root.closeFullscreen()
        }
    }

    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            // Find duplicates by trackTitle prefix
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }

            // Pick the one with non-empty trackArtUrl, or fallback to the first
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen
        onActiveChanged: {
            if (!mediaControlsLoader.active && root.realPlayers.length === 0) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: Math.min(playerColumnLayout.implicitHeight, (screen?.height ?? 0) - Math.max(margins.top, margins.bottom) - Appearance.sizes.barHeight)
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: !BarOptions.bottom || BarOptions.vertical
                bottom: BarOptions.bottom && !BarOptions.vertical
                left: !(BarOptions.vertical && BarOptions.bottom)
                right: BarOptions.vertical && BarOptions.bottom
            }
            margins {
                top: BarOptions.vertical ? ((panelWindow.screen.height / 2) - widgetHeight * 1.5) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: BarOptions.vertical ?Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
                right: Appearance.sizes.barHeight
            }

            mask: Region {
                item: playerScroll
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.mediaControlsOpen = false;
                }
            }

            Flickable {
                id: playerScroll
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height
                contentHeight: playerColumnLayout.implicitHeight
            }

            ColumnLayout {
                id: playerColumnLayout
                parent: playerScroll.contentItem
                width: playerScroll.width
                spacing: -Appearance.sizes.elevationMargin // Shadow overlap okay

                Repeater {
                    model: ScriptModel {
                        values: root.meaningfulPlayers
                    }
                    delegate: PlayerControl {
                        required property MprisPlayer modelData
                        player: modelData
                        canExpand: true
                        onExpandRequested: GlobalStates.mediaFullscreenRequested(modelData, panelWindow.screen)
                        implicitWidth: root.widgetWidth
                        radius: root.popupRounding
                    }
                }

                Item {
                    // No player placeholder
                    Layout.alignment: {
                        if (panelWindow.anchors.left)
                            return Qt.AlignLeft;
                        if (panelWindow.anchors.right)
                            return Qt.AlignRight;
                        return Qt.AlignHCenter;
                    }
                    Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
                    Layout.rightMargin: Appearance.sizes.hyprlandGapsOut
                    visible: root.meaningfulPlayers.length === 0
                    implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                    implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                    StyledRectangularShadow {
                        target: placeholderBackground
                    }

                    Rectangle {
                        id: placeholderBackground
                        anchors.centerIn: parent
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding
                        property real padding: 20
                        implicitWidth: placeholderLayout.implicitWidth + padding * 2
                        implicitHeight: placeholderLayout.implicitHeight + padding * 2

                        ColumnLayout {
                            id: placeholderLayout
                            anchors.centerIn: parent

                            StyledText {
                                text: Translation.tr("No active player")
                                font.pixelSize: Appearance.font.pixelSize.large
                            }
                            StyledText {
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            root.toggle();
            if (GlobalStates.mediaControlsOpen)
                Notifications.timeoutAll();
        }

        function close(): void {
            root.close();
        }

        function open(): void {
            root.open();
            if (GlobalStates.mediaControlsOpen)
                Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: root.toggle()
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: root.open()
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: root.close()
    }
}
