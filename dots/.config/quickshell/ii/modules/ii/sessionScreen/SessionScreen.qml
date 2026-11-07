import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Loader {
        id: sessionLoader
        active: GlobalStates.sessionOpen
        onActiveChanged: {
            if (sessionLoader.active) {
                SessionWarnings.refresh();
                Session.refreshWindowsBootEntry();
            }
        }

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (GlobalStates.screenLocked) {
                    GlobalStates.sessionOpen = false;
                }
            }
        }

        sourceComponent: PanelWindow { // Session menu
            id: sessionRoot
            visible: sessionLoader.active
            property string subtitle
            property bool rebootChoiceOpen: false

            function hide() {
                GlobalStates.sessionOpen = false;
            }

            function closeRebootChoice() {
                if (!rebootChoiceOpen) return;
                rebootChoiceOpen = false;
                sessionReboot.forceActiveFocus();
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, Appearance.m3colors.darkmode ? 0.05 : 0.12)

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 0
            implicitHeight: root.focusedScreen?.height ?? 0

            MouseArea {
                id: sessionMouseArea
                anchors.fill: parent
                onClicked: {
                    sessionRoot.hide();
                }
            }

            ColumnLayout { // Content column
                id: contentColumn
                anchors.centerIn: parent
                spacing: 15

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (sessionRoot.rebootChoiceOpen)
                            sessionRoot.closeRebootChoice();
                        else
                            sessionRoot.hide();
                    }
                }

                ColumnLayout { // Blurrable menu content
                    id: menuContent
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 15
                    property real menuBlurAmount: sessionRoot.rebootChoiceOpen ? 1 : 0
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
                            // Title
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
                            // Small instruction
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.normal
                            text: Translation.tr("Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel")
                        }
                    }

                    GridLayout {
                        columns: 4
                        columnSpacing: 15
                        rowSpacing: 15

                        SessionActionButton {
                            id: sessionLock
                            focus: sessionRoot.visible
                            buttonIcon: "lock"
                            buttonText: Translation.tr("Lock")
                            onClicked: {
                                Session.lock();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.right: sessionSleep
                            KeyNavigation.down: sessionHibernate
                        }
                        SessionActionButton {
                            id: sessionSleep
                            buttonIcon: "dark_mode"
                            buttonText: Translation.tr("Sleep")
                            onClicked: {
                                Session.suspend();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.left: sessionLock
                            KeyNavigation.right: sessionLogout
                            KeyNavigation.down: sessionShutdown
                        }
                        SessionActionButton {
                            id: sessionLogout
                            buttonIcon: "logout"
                            buttonText: Translation.tr("Logout")
                            onClicked: {
                                Session.logout();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.left: sessionSleep
                            KeyNavigation.right: sessionTaskManager
                            KeyNavigation.down: sessionReboot
                        }
                        SessionActionButton {
                            id: sessionTaskManager
                            buttonIcon: "browse_activity"
                            buttonText: Translation.tr("Task Manager")
                            onClicked: {
                                Session.launchTaskManager();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.left: sessionLogout
                            KeyNavigation.down: sessionFirmwareReboot
                        }

                        SessionActionButton {
                            id: sessionHibernate
                            buttonIcon: "downloading"
                            buttonText: Translation.tr("Hibernate")
                            onClicked: {
                                Session.hibernate();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.up: sessionLock
                            KeyNavigation.right: sessionShutdown
                        }
                        SessionActionButton {
                            id: sessionShutdown
                            buttonIcon: "power_settings_new"
                            buttonText: Translation.tr("Shutdown")
                            onClicked: {
                                Session.poweroff();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.left: sessionHibernate
                            KeyNavigation.right: sessionReboot
                            KeyNavigation.up: sessionSleep
                        }
                        SessionActionButton {
                            id: sessionReboot
                            buttonIcon: "restart_alt"
                            buttonText: Translation.tr("Reboot")
                            tooltipExtraText: Session.windowsBootEntryAvailable ? Translation.tr("Direct reboot into Windows is available") : ""
                            tooltipEnabled: !sessionRoot.rebootChoiceOpen
                            onClicked: {
                                if (Session.windowsBootEntryAvailable) {
                                    sessionRoot.rebootChoiceOpen = true;
                                } else {
                                    Session.reboot();
                                    sessionRoot.hide();
                                }
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = tooltipExtraText
                                        ? `${buttonText}\n${tooltipExtraText}`
                                        : buttonText;
                            }
                            KeyNavigation.left: sessionShutdown
                            KeyNavigation.right: sessionFirmwareReboot
                            KeyNavigation.up: sessionLogout
                        }
                        SessionActionButton {
                            id: sessionFirmwareReboot
                            buttonIcon: "settings_applications"
                            buttonText: Translation.tr("Reboot to firmware settings")
                            onClicked: {
                                Session.rebootToFirmware();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                            KeyNavigation.up: sessionTaskManager
                            KeyNavigation.left: sessionReboot
                        }
                    }
                }

                DescriptionLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: sessionRoot.subtitle
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
                visible: sessionRoot.rebootChoiceOpen
                hoverEnabled: true
                onClicked: sessionRoot.closeRebootChoice()
            }

            RowLayout { // Reboot type choice
                id: rebootChoiceRow
                anchors.centerIn: parent
                spacing: 15
                opacity: sessionRoot.rebootChoiceOpen ? 1 : 0
                scale: sessionRoot.rebootChoiceOpen ? 1 : 0.95
                visible: opacity > 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on scale {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        sessionRoot.closeRebootChoice();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        event.accepted = true;
                    }
                }

                SessionActionButton {
                    id: normalRebootButton
                    focus: sessionRoot.rebootChoiceOpen
                    buttonIcon: "restart_alt"
                    buttonText: Translation.tr("Normal reboot")
                    onClicked: {
                        Session.reboot();
                        sessionRoot.hide();
                    }
                    onFocusChanged: {
                        if (focus)
                            sessionRoot.subtitle = buttonText;
                    }
                    KeyNavigation.right: windowsRebootButton
                }

                SessionActionButton {
                    id: windowsRebootButton
                    iconSource: "microsoft-symbolic.svg"
                    buttonText: Translation.tr("Reboot into Windows")
                    onClicked: {
                        Session.rebootToWindows();
                        sessionRoot.hide();
                    }
                    onFocusChanged: {
                        if (focus)
                            sessionRoot.subtitle = buttonText;
                    }
                    KeyNavigation.left: normalRebootButton
                }
            }
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

    IpcHandler {
        target: "session"

        function toggle(): void {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }

        function close(): void {
            GlobalStates.sessionOpen = false;
        }

        function open(): void {
            GlobalStates.sessionOpen = true;
        }
    }

    GlobalShortcut {
        name: "sessionToggle"
        description: "Toggles session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }
    }

    GlobalShortcut {
        name: "sessionOpen"
        description: "Opens session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = true;
        }
    }

    GlobalShortcut {
        name: "sessionClose"
        description: "Closes session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = false;
        }
    }
}
