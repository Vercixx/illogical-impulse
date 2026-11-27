pragma ComponentBehavior: Bound
import QtQuick
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

        PlayerControl {
            anchors.centerIn: parent
            width: Math.min(720, parent.width - 32)
            height: Math.min(480, parent.height - 104)
            radius: Appearance.rounding.large
            player: root.player
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
