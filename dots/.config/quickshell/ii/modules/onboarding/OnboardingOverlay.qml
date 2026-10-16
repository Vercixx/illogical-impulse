import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    function askRestart() {
        if (Onboarding.active)
            return;
        Onboarding.restartDialogOpen = true;
    }

    IpcHandler {
        target: "onboarding"

        function open(): void {
            root.askRestart();
        }
        function finish(): void {
            Onboarding.finish();
        }
    }

    GlobalShortcut {
        name: "onboardingOpen"
        description: "Asks to go through onboarding again"
        onPressed: root.askRestart()
    }

    LazyLoader {
        active: Config.ready && Onboarding.active
        component: OnboardingWindow {}
    }

    LazyLoader {
        active: Onboarding.restartDialogOpen
        component: PanelWindow {
            WlrLayershell.namespace: "quickshell:onboarding"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WindowDialog {
                id: restartDialog
                anchors.fill: parent
                backgroundWidth: 400
                radius: 0
                Component.onCompleted: {
                    show = true;
                    forceActiveFocus();
                }
                onDismiss: {
                    show = false;
                    closeTimer.start();
                }

                Timer {
                    id: closeTimer
                    interval: Appearance.animation.elementMoveFast.duration
                    onTriggered: Onboarding.restartDialogOpen = false
                }

                WindowDialogTitle {
                    Layout.fillWidth: true
                    text: Translation.tr("Go through onboarding again?")
                }
                WindowDialogParagraph {
                    Layout.fillWidth: true
                    text: Translation.tr("You'll be able to redo the interactive guide, but note that it cannot be closed until you finish it.")
                }
                WindowDialogButtonRow {
                    Layout.fillWidth: true
                    Item {
                        Layout.fillWidth: true
                    }
                    DialogButton {
                        buttonText: Translation.tr("No")
                        onClicked: restartDialog.dismiss()
                    }
                    DialogButton {
                        buttonText: Translation.tr("Yes")
                        onClicked: Onboarding.restart()
                    }
                }
            }
        }
    }
}
