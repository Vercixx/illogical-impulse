pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

FocusScope {
    id: root

    // Set when shown inside the lock screen: hides Lock and Task Manager, guards session-ending actions
    property LockContext lockContext: null
    property string subtitle
    property bool rebootChoiceOpen: false

    signal closed()

    Component.onCompleted: {
        SessionWarnings.refresh();
        Session.refreshWindowsBootEntry();
        (root.lockContext ? sessionSleep : sessionLock).forceActiveFocus();
    }

    function run(lockAction, action) {
        const guarded = root.lockContext && lockAction !== undefined
            && (Config.options.lock.security.requirePasswordToPower || lockAction === LockContext.ActionEnum.RebootWindows);
        if (guarded) {
            root.lockContext.targetAction = lockAction;
            root.closed();
            root.lockContext.shouldReFocus();
            return;
        }
        action();
        root.closed();
    }

    function closeRebootChoice() {
        if (!rebootChoiceOpen) return;
        rebootChoiceOpen = false;
        sessionReboot.forceActiveFocus();
    }

    HoverHandler {
        onPointChanged: root.lockContext?.reveal()
    }

    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Escape) return;
        if (root.rebootChoiceOpen)
            root.closeRebootChoice();
        else
            root.closed();
        event.accepted = true;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    ColumnLayout {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 15

        ColumnLayout {
            id: menuContent
            Layout.alignment: Qt.AlignHCenter
            spacing: 15
            property real menuBlurAmount: root.rebootChoiceOpen ? 1 : 0
            layer.enabled: menuBlurAmount > 0
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: menuContent.menuBlurAmount
                blurMax: 32
            }

            Behavior on menuBlurAmount {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.title
                        variableAxes: Appearance.font.variableAxes.title
                    }
                    text: Translation.tr("Session")
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: Translation.tr("Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel")
                }
            }

            GridLayout {
                id: buttonGrid
                Layout.alignment: Qt.AlignHCenter
                columns: root.lockContext ? 3 : 4
                columnSpacing: 15
                rowSpacing: 15

                Keys.onPressed: event => {
                    root.lockContext?.reveal();
                    let step = 0;
                    if (event.key === Qt.Key_Left) step = -1;
                    else if (event.key === Qt.Key_Right) step = 1;
                    else if (event.key === Qt.Key_Up) step = -columns;
                    else if (event.key === Qt.Key_Down) step = columns;
                    if (step === 0) return;
                    event.accepted = true;

                    const buttons = Array.from(buttonGrid.children).filter(b => b.visible);
                    const index = buttons.findIndex(b => b.activeFocus);
                    const target = index + step;
                    const sameRow = Math.floor(target / columns) === Math.floor(index / columns);
                    if (index < 0 || target < 0 || target >= buttons.length) return;
                    if (Math.abs(step) === 1 && !sameRow) return;
                    buttons[target].forceActiveFocus();
                }

                MenuButton {
                    id: sessionLock
                    visible: !root.lockContext
                    buttonIcon: "lock"
                    buttonText: Translation.tr("Lock")
                    onClicked: root.run(undefined, () => Session.lock())
                }
                MenuButton {
                    id: sessionSleep
                    buttonIcon: "dark_mode"
                    buttonText: Translation.tr("Sleep")
                    onClicked: root.run(undefined, () => Session.suspend())
                }
                MenuButton {
                    buttonIcon: "logout"
                    buttonText: Translation.tr("Logout")
                    onClicked: root.run(LockContext.ActionEnum.Logout, () => Session.logout())
                }
                MenuButton {
                    visible: !root.lockContext
                    buttonIcon: "browse_activity"
                    buttonText: Translation.tr("Task Manager")
                    onClicked: root.run(undefined, () => Session.launchTaskManager())
                }
                MenuButton {
                    buttonIcon: "downloading"
                    buttonText: Translation.tr("Hibernate")
                    onClicked: root.run(undefined, () => Session.hibernate())
                }
                MenuButton {
                    buttonIcon: "power_settings_new"
                    buttonText: Translation.tr("Shutdown")
                    onClicked: root.run(LockContext.ActionEnum.Poweroff, () => Session.poweroff())
                }
                MenuButton {
                    id: sessionReboot
                    buttonIcon: "restart_alt"
                    buttonText: Translation.tr("Reboot")
                    tooltipExtraText: Session.windowsBootEntryAvailable ? Translation.tr("Direct reboot into Windows is available") : ""
                    tooltipEnabled: !root.rebootChoiceOpen
                    onClicked: {
                        if (Session.windowsBootEntryAvailable)
                            root.rebootChoiceOpen = true;
                        else
                            root.run(LockContext.ActionEnum.Reboot, () => Session.reboot());
                    }
                    onFocusChanged: {
                        if (focus && tooltipExtraText)
                            root.subtitle = `${buttonText}\n${tooltipExtraText}`;
                    }
                }
                MenuButton {
                    buttonIcon: "settings_applications"
                    buttonText: Translation.tr("Reboot to firmware settings")
                    onClicked: root.run(LockContext.ActionEnum.RebootFirmware, () => Session.rebootToFirmware())
                }
            }
        }

        DescriptionLabel {
            Layout.alignment: Qt.AlignHCenter
            text: root.subtitle
        }
    }

    ColumnLayout {
        anchors {
            top: contentColumn.bottom
            topMargin: 10
            horizontalCenter: contentColumn.horizontalCenter
        }
        spacing: 10

        Loader {
            Layout.alignment: Qt.AlignHCenter
            active: SessionWarnings.downloadRunning
            visible: active
            sourceComponent: DescriptionLabel {
                text: Translation.tr("There might be a download in progress. Check your Downloads folder.")
                textColor: Appearance.m3colors.m3onErrorContainer
                color: Appearance.m3colors.m3errorContainer
            }
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter
            active: SessionWarnings.packageManagerRunning
            visible: active
            sourceComponent: DescriptionLabel {
                text: Translation.tr("Your package manager is running")
                textColor: Appearance.m3colors.m3onErrorContainer
                color: Appearance.m3colors.m3errorContainer
            }
        }
    }

    MouseArea { // Block interaction with the blurred menu while choosing a reboot type
        anchors.fill: parent
        visible: root.rebootChoiceOpen
        hoverEnabled: true
        onClicked: root.closeRebootChoice()
    }

    RowLayout {
        id: rebootChoiceRow
        anchors.centerIn: parent
        spacing: 15
        opacity: root.rebootChoiceOpen ? 1 : 0
        scale: root.rebootChoiceOpen ? 1 : 0.95
        visible: opacity > 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on scale {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closeRebootChoice();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                event.accepted = true;
            }
        }

        MenuButton {
            id: normalRebootButton
            focus: root.rebootChoiceOpen
            buttonIcon: "restart_alt"
            buttonText: Translation.tr("Normal reboot")
            onClicked: root.run(LockContext.ActionEnum.Reboot, () => Session.reboot())
            KeyNavigation.right: windowsRebootButton
        }

        MenuButton {
            id: windowsRebootButton
            iconSource: "microsoft-symbolic.svg"
            buttonText: Translation.tr("Reboot into Windows")
            onClicked: root.run(LockContext.ActionEnum.RebootWindows, () => Session.rebootToWindows())
            KeyNavigation.left: normalRebootButton
        }
    }

    component MenuButton: SessionActionButton {
        onFocusChanged: {
            if (focus)
                root.subtitle = buttonText;
        }
    }

    component DescriptionLabel: Rectangle {
        id: descriptionLabel
        property string text
        property color textColor: Appearance.colors.colOnTooltip
        color: Appearance.colors.colTooltip
        clip: true
        radius: Appearance.rounding.normal
        implicitHeight: descriptionLabelText.implicitHeight + 10 * 2
        implicitWidth: descriptionLabelText.implicitWidth + 15 * 2

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        StyledText {
            id: descriptionLabelText
            anchors.centerIn: parent
            color: descriptionLabel.textColor
            text: descriptionLabel.text
        }
    }
}
