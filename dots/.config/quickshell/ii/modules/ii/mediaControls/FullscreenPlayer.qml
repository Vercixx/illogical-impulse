pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

PanelWindow {
    id: root
    required property MprisPlayer player
    signal dismissRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:fullscreenPlayer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: Appearance.colors.colLayer0

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.dismissRequested()

        GridLayout {
            id: content
            readonly property bool showLyrics: Config.options.media.showLyrics
            readonly property bool stacked: showLyrics && width < 760
            anchors.centerIn: parent
            anchors.verticalCenterOffset: showLyrics ? 24 : 0
            width: Math.min(showLyrics ? 1200 : 720, parent.width - 32)
            height: showLyrics ? Math.min(680, parent.height - 120) : Math.min(480, parent.height - 104)
            columns: stacked || !showLyrics ? 1 : 2
            columnSpacing: 24
            rowSpacing: 16

            PlayerControl {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 640
                Layout.minimumHeight: Math.min(Appearance.sizes.mediaControlsHeight, content.height)
                Layout.maximumHeight: content.stacked ? 250 : 480
                radius: Appearance.rounding.large
                player: root.player
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 420
                Layout.preferredHeight: content.stacked ? 300 : content.height
                visible: active
                active: content.showLyrics
                sourceComponent: LyricsView {
                    player: root.player
                }
            }
        }

        RippleButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 16
            width: 40
            height: 40
            focus: true
            Accessible.name: Translation.tr("Close")
            onClicked: root.dismissRequested()

            contentItem: MaterialSymbol {
                text: "close"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            StyledToolTip {
                text: Translation.tr("Close")
            }
        }
    }
}
