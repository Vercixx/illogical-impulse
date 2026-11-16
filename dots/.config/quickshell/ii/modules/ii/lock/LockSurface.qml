import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.ii.bar as Bar
import qs.modules.ii.sessionScreen
import Quickshell
import Quickshell.Services.SystemTray

MouseArea {
    id: root
    required property LockContext context
    readonly property bool revealed: GlobalStates.screenLockRevealed
    property bool sessionMenuOpen: false

    onRevealedChanged: {
        if (revealed) return;
        sessionMenuOpen = false;
        forceFieldFocus();
    }

    function forceFieldFocus() {
        if (root.sessionMenuOpen) return;
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        root.context.reveal();
        forceFieldFocus();
    }
    // Mapping the surface under a still cursor also sends a hover event
    property point lastMousePos: Qt.point(-1, -1)
    onPositionChanged: mouse => {
        const moved = lastMousePos.x >= 0 && Math.abs(mouse.x - lastMousePos.x) + Math.abs(mouse.y - lastMousePos.y) > 2;
        lastMousePos = Qt.point(mouse.x, mouse.y);
        if (moved) root.context.reveal();
        forceFieldFocus();
    }

    // Content appearing animation
    property bool shown: false
    property real contentScale: (shown && revealed) ? 1 : 0.95
    property real contentOpacity: (shown && revealed) ? 1 : 0
    Behavior on contentScale {
        animation: Appearance.animation.lockReveal.numberAnimation.createObject(this)
    }
    Behavior on contentOpacity {
        animation: Appearance.animation.lockReveal.numberAnimation.createObject(this)
    }

    Component.onCompleted: {
        forceFieldFocus();
        shown = true;
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.reveal();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        }
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    // Kept visible while hidden so the password field holds focus and catches the first key
    ColumnLayout {
        id: userColumn
        anchors.centerIn: parent
        spacing: 16
        scale: root.contentScale
        opacity: root.contentOpacity

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 128
            implicitHeight: 128

            MaterialSymbol {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                fill: 1
                text: "account_circle"
                iconSize: 128
                color: Appearance.colors.colOnLayer0
            }
            StyledImage {
                id: avatar
                anchors.fill: parent
                source: Directories.userAvatarPathAccountsService
                fallbacks: [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Circle {
                        diameter: avatar.height
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: SystemInfo.realName || SystemInfo.username
            color: Appearance.colors.colOnLayer0
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
            font {
                family: Appearance.font.family.title
                pixelSize: Appearance.font.pixelSize.title
                variableAxes: Appearance.font.variableAxes.title
            }
        }

        Toolbar {
            id: passwordIsland
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8

            // Fingerprint
            Loader {
                Layout.leftMargin: 10
                Layout.rightMargin: 6
                Layout.alignment: Qt.AlignVCenter
                active: root.context.fingerprintsConfigured
                visible: active

                sourceComponent: MaterialSymbol {
                    id: fingerprintIcon
                    fill: 1
                    text: "fingerprint"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            ToolbarTextField {
                id: passwordBox
                Layout.rightMargin: -Layout.leftMargin
                placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

                // Style
                clip: true
                font.pixelSize: Appearance.font.pixelSize.small
                selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
                selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

                // Password
                enabled: !root.context.unlockInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData

                // Synchronizing (across monitors) and unlocking
                onTextChanged: root.context.currentText = this.text
                onAccepted: {
                    if (!root.revealed) {
                        root.context.reveal();
                        return;
                    }
                    root.context.tryUnlock(root.ctrlHeld);
                }
                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        passwordBox.text = root.context.currentText;
                    }
                }

                Keys.onPressed: event => {
                    root.context.resetClearTimer();
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: passwordBox.width - 8
                        height: passwordBox.height
                        radius: height / 2
                    }
                }

                // Shake when wrong password
                ErrorShakeAnimation {
                    id: wrongPasswordShakeAnim
                    target: passwordBox
                }
                Connections {
                    target: GlobalStates
                    function onScreenUnlockFailedChanged() {
                        if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                    }
                }

                // We're drawing dots manually
                property bool materialShapeChars: Config.options.lock.materialShapeChars
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
                Loader {
                    active: passwordBox.materialShapeChars
                    anchors {
                        fill: parent
                        leftMargin: passwordBox.padding
                        rightMargin: passwordBox.padding
                    }
                    sourceComponent: PasswordChars {
                        length: root.context.currentText.length
                        selectionStart: passwordBox.selectionStart
                        selectionEnd: passwordBox.selectionEnd
                        cursorPosition: passwordBox.cursorPosition
                    }
                }
            }

            ToolbarButton {
                id: confirmButton
                implicitWidth: height
                toggled: true
                enabled: !root.context.unlockInProgress && root.revealed
                colBackgroundToggled: Appearance.colors.colPrimary

                onClicked: root.context.tryUnlock()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    iconSize: 24
                    text: {
                        switch (root.context.targetAction) {
                        case LockContext.ActionEnum.Poweroff:
                            return "power_settings_new";
                        case LockContext.ActionEnum.Reboot:
                        case LockContext.ActionEnum.RebootWindows:
                            return "restart_alt";
                        case LockContext.ActionEnum.RebootFirmware:
                            return "settings_applications";
                        case LockContext.ActionEnum.Logout:
                            return "logout";
                        default:
                            return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                        }
                    }
                    color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                }
            }
        }
    }

    Toolbar {
        id: bottomIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        scale: root.contentScale
        opacity: root.contentOpacity
        visible: opacity > 0

        // Keyboard layout (Xkb)
        Row {
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.fillHeight: true
            spacing: 8

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                fill: 1
                text: "keyboard_alt"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: HyprlandXkb.currentLayoutCode
                color: Appearance.colors.colOnSurfaceVariant
                animateChange: true
            }
        }

        // Keyboard layout (Fcitx)
        Bar.SysTray {
            Layout.rightMargin: 6
            Layout.alignment: Qt.AlignVCenter
            showSeparator: false
            showOverflowMenu: false
            pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
            visible: pinnedItems.length > 0
        }

        IconAndTextPair {
            visible: Battery.available
            icon: Battery.isCharging ? "bolt" : "battery_android_full"
            text: Math.round(Battery.percentage * 100)
            color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
        }

        IconToolbarButton {
            text: "power_settings_new"
            onClicked: {
                root.context.reveal();
                root.sessionMenuOpen = true;
            }
        }
    }

    FadeLoader {
        anchors.fill: parent
        shown: root.sessionMenuOpen
        sourceComponent: Rectangle {
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, Appearance.m3colors.darkmode ? 0.05 : 0.12)

            SessionMenu {
                anchors.fill: parent
                lockContext: root.context
                onClosed: {
                    root.sessionMenuOpen = false;
                    root.forceFieldFocus();
                }
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
