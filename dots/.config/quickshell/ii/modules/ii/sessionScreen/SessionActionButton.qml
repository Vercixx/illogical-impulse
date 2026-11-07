import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button

    property string buttonIcon
    property string buttonText
    property string iconSource: ""
    property string tooltipExtraText: ""
    property bool tooltipEnabled: true
    property bool keyboardDown: false
    property real size: 120

    buttonRadius: (button.focus || button.down) ? size / 2 : Appearance.rounding.verylarge
    colBackground: button.keyboardDown ? Appearance.colors.colSecondaryContainerActive : 
        button.focus ? Appearance.colors.colPrimary : 
        Appearance.colors.colSecondaryContainer
    colBackgroundHover: Appearance.colors.colPrimary
    colRipple: Appearance.colors.colPrimaryActive
    property color colText: (button.down || button.keyboardDown || button.focus || button.hovered) ?
        Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    background.implicitHeight: size
    background.implicitWidth: size

    Behavior on buttonRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onActiveFocusChanged: {
        if (!activeFocus)
            keyboardDown = false;
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true
            button.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false
            event.accepted = true;
        }
    }

    contentItem: Item {
        implicitWidth: squareIcon.implicitWidth
        implicitHeight: squareIcon.implicitHeight

        MaterialSymbol {
            id: squareIcon
            visible: button.iconSource === ""
            anchors.fill: parent
            color: button.colText
            horizontalAlignment: Text.AlignHCenter
            iconSize: 45
            text: button.buttonIcon
        }

        Loader {
            active: button.iconSource !== ""
            anchors.centerIn: parent
            width: 36
            height: 36
            sourceComponent: CustomIcon {
                width: 36
                height: 36
                colorize: true
                color: button.colText
                source: button.iconSource
            }
        }
    }

    StyledToolTip {
        text: button.tooltipExtraText
            ? `${button.buttonText}\n${button.tooltipExtraText}`
            : button.buttonText
        extraVisibleCondition: button.tooltipEnabled
    }

}
