pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property string icon
    property string title
    property string description
    property var tasks: []
    property bool polling: false

    property int currentTask: 0
    property var skipped: []
    property var base: null
    readonly property bool done: currentTask >= tasks.length
    readonly property bool hidden: GlobalStates.regionSelectorOpen
    readonly property Item maskItem: hidden ? emptyMask : card

    signal next

    function snapshot() {
        const windows = {};
        for (const w of HyprlandData.windowList) {
            windows[w.address] = {
                "class": w.class,
                "at": `${w.at}`,
                "size": `${w.size}`,
                "workspace": w.workspace.id,
                "special": w.workspace.name.startsWith("special:"),
                "floating": w.floating,
                "pinned": w.pinned,
                "fullscreen": w.fullscreen
            };
        }
        const workspace = HyprlandData.activeWorkspace?.id;
        return {
            "windows": windows,
            "windowsHere": HyprlandData.windowList.filter(w => w.workspace.id === workspace).length,
            "workspace": workspace,
            "activeWindow": Hyprland.activeToplevel?.address ?? "",
            "clipboard": Quickshell.clipboardText,
            "specialShown": HyprlandData.monitors.some(m => m.specialWorkspace?.name.startsWith("special:"))
        };
    }

    function advance(skip) {
        if (skip)
            root.skipped = [...root.skipped, root.currentTask];
        root.currentTask++;
        root.base = root.snapshot();
    }

    Component.onCompleted: root.base = root.snapshot()

    Timer {
        running: !root.done
        interval: 250
        repeat: true
        onTriggered: {
            if (root.polling)
                HyprlandData.updateWindowList();
            if (root.tasks[root.currentTask].check(root.base, root.snapshot()))
                root.advance(false);
        }
    }

    Item {
        id: emptyMask
    }

    StyledRectangularShadow {
        target: card
        opacity: card.opacity
    }
    Rectangle {
        id: card
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 32
        }
        width: 500
        implicitHeight: cardColumn.implicitHeight + 40
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true
        opacity: root.hidden ? 0 : 1

        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: cardColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                MaterialShapeWrappedMaterialSymbol {
                    text: root.icon
                    iconSize: Appearance.font.pixelSize.huge
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colOnLayer0
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.title
                        variableAxes: Appearance.font.variableAxes.title
                    }
                }
                StyledText {
                    animateChange: true
                    text: `${Math.min(root.currentTask + 1, root.tasks.length)}/${root.tasks.length}`
                    color: Appearance.colors.colSubtext
                }
            }

            StyledText {
                visible: root.description !== ""
                Layout.fillWidth: true
                text: root.description
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.tasks
                    delegate: RowLayout {
                        id: taskRow
                        required property var modelData
                        required property int index
                        readonly property bool finished: index < root.currentTask
                        readonly property bool current: index === root.currentTask
                        readonly property bool skipped: root.skipped.includes(index)
                        Layout.fillWidth: true
                        Layout.minimumHeight: 32
                        spacing: 10
                        opacity: taskRow.finished || taskRow.current ? 1 : 0.5

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        MaterialSymbol {
                            text: taskRow.skipped ? "skip_next" : taskRow.finished ? "check_circle" : "radio_button_unchecked"
                            fill: taskRow.finished ? 1 : 0
                            iconSize: Appearance.font.pixelSize.larger
                            color: taskRow.finished && !taskRow.skipped ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: taskRow.modelData.text
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnLayer0
                        }
                        ColumnLayout {
                            spacing: 4

                            KeyCombo {
                                Layout.alignment: Qt.AlignRight
                                keys: taskRow.modelData.keys
                            }
                            RowLayout {
                                visible: !!taskRow.modelData.altKeys
                                Layout.alignment: Qt.AlignRight
                                spacing: 6

                                StyledText {
                                    text: Translation.tr("or")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                                KeyCombo {
                                    keys: taskRow.modelData.altKeys ?? []
                                }
                            }
                        }
                        RippleButton {
                            visible: taskRow.current
                            implicitHeight: 28
                            implicitWidth: skipText.implicitWidth + 20
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colLayer2
                            onClicked: root.advance(true)
                            contentItem: StyledText {
                                id: skipText
                                horizontalAlignment: Text.AlignHCenter
                                text: Translation.tr("Skip")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer2
                            }
                        }
                    }
                }
            }

            OnboardingButton {
                visible: root.done
                Layout.alignment: Qt.AlignRight
                buttonText: Translation.tr("Continue")
                onClicked: root.next()
            }
        }
    }
}
