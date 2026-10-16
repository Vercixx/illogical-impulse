import QtQuick
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root
    property bool primary: true

    implicitHeight: 40
    implicitWidth: buttonTextWidget.implicitWidth + 48
    buttonRadius: Appearance.rounding.full
    colBackground: primary ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
    colBackgroundHover: primary ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
    colRipple: primary ? Appearance.colors.colPrimaryActive : Appearance.colors.colSecondaryContainerActive

    contentItem: StyledText {
        id: buttonTextWidget
        text: root.buttonText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.primary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
    }
}
