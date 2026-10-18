import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton { // Right sidebar button
    id: root
    property var host: null
    readonly property bool vertical: Config.options.bar.vertical
    readonly property real realSpacing: vertical ? 6 : 15
    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : (host?.colForeground ?? Appearance.colors.colOnLayer0)

    implicitWidth: indicators.implicitWidth + (vertical ? 6 : 5) * 2
    implicitHeight: indicators.implicitHeight + 5 * 2

    buttonRadius: Appearance.rounding.full
    colBackground: host?.sideHovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarRightOpen

    Behavior on colText {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    onPressed: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    component Indicator: Revealer {
        id: indicator
        vertical: root.vertical
        Layout.fillHeight: !root.vertical
        Layout.fillWidth: root.vertical
        property real gap: reveal ? root.realSpacing : 0
        Layout.rightMargin: root.vertical ? 0 : gap
        Layout.bottomMargin: root.vertical ? gap : 0
        Behavior on gap {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    BoxLayout {
        id: indicators
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: 0

        Indicator {
            reveal: Audio.sink?.audio?.muted ?? false
            MaterialSymbol {
                text: "volume_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.colText
            }
        }
        Indicator {
            reveal: Audio.source?.audio?.muted ?? false
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.colText
            }
        }
        HyprlandXkbIndicator {
            vertical: root.vertical
            Layout.alignment: Qt.AlignCenter
            Layout.rightMargin: root.vertical ? 0 : root.realSpacing
            Layout.bottomMargin: root.vertical ? root.realSpacing : 0
            color: root.colText
        }
        Indicator {
            reveal: Notifications.silent || Notifications.unread > 0
            implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
            implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
            NotificationUnreadCount {
                id: notificationUnreadCount
                color: root.colText
            }
        }
        MaterialSymbol {
            Layout.alignment: Qt.AlignCenter
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: root.colText
        }
        MaterialSymbol {
            Layout.alignment: Qt.AlignCenter
            Layout.leftMargin: root.vertical ? 0 : root.realSpacing
            Layout.topMargin: root.vertical ? root.realSpacing : 0
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: root.colText
        }
    }
}
