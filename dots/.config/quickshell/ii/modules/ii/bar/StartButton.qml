import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Opens the search overview, which BarOptions.taskbar turns into a start menu
RippleButton {
    id: root

    property var host: null
    property real buttonPadding: 5

    implicitWidth: icon.width + buttonPadding * 2
    implicitHeight: icon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackground: root.host?.sideHovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.overviewOpen

    onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen

    CustomIcon {
        id: icon
        anchors.centerIn: parent
        width: 19.5
        height: 19.5
        source: Config.options.bar.topLeftIcon == 'distro' ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`
        colorize: true
        color: root.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
    }
}
