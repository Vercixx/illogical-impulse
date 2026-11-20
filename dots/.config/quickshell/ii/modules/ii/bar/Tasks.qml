pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Taskbar: pinned and open apps. Click focuses; hover previews windows; right click pins the popup
Item {
    id: root

    property var host: null
    readonly property bool vertical: BarOptions.vertical
    readonly property real buttonSize: vertical ? Appearance.sizes.baseVerticalBarWidth : Appearance.sizes.baseBarHeight

    property Item hoveredButton: null
    property Item menuButton: null
    property bool hoverShown: false
    readonly property Item popupButton: menuButton ?? (hoverShown ? hoveredButton : null)

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    function addressOf(toplevel): string {
        return `0x${toplevel?.HyprlandToplevel?.address}`;
    }

    function dismissPopup() {
        root.menuButton = null;
        root.hoverShown = false;
    }

    Timer {
        id: hoverDelay
        interval: 400
        onTriggered: root.hoverShown = root.hoveredButton !== null && root.hoveredButton.appEntry.toplevels.length > 0
    }
    Timer {
        id: leaveDelay
        interval: 250
        onTriggered: {
            if (!popupArea.containsMouse && !(root.hoveredButton?.hovered ?? false))
                root.dismissPopup();
        }
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        spacing: 2

        Repeater {
            model: ScriptModel {
                values: TaskbarApps.apps
                objectProp: "appId"
            }

            delegate: Loader {
                id: slot
                required property var modelData
                sourceComponent: slot.modelData.appId === "SEPARATOR" ? separator : taskButton

                Component {
                    id: separator
                    Item {
                        implicitWidth: root.vertical ? root.buttonSize : 9
                        implicitHeight: root.vertical ? 9 : root.buttonSize
                        Rectangle {
                            anchors.centerIn: parent
                            width: root.vertical ? parent.width * 0.5 : 1
                            height: root.vertical ? 1 : parent.height * 0.5
                            color: Appearance.colors.colOutlineVariant
                        }
                    }
                }

                Component {
                    id: taskButton
                    TaskButton {
                        appEntry: slot.modelData
                    }
                }
            }
        }
    }

    component TaskButton: RippleButton {
        id: button
        required property var appEntry
        property var desktopEntry: DesktopEntries.heuristicLookup(appEntry.appId)
        readonly property var toplevels: appEntry.toplevels
        readonly property bool active: toplevels.some(t => t.activated)

        Connections {
            target: DesktopEntries
            function onApplicationsChanged() {
                button.desktopEntry = DesktopEntries.heuristicLookup(button.appEntry.appId);
            }
        }

        implicitWidth: root.buttonSize
        implicitHeight: root.buttonSize
        buttonRadius: Appearance.rounding.small
        colBackground: active ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active

        onHoveredChanged: {
            if (hovered) {
                root.hoveredButton = button;
                leaveDelay.stop();
                if (root.popupButton !== null && root.popupButton !== button) {
                    root.menuButton = null;
                    root.hoverShown = toplevels.length > 0;
                } else {
                    hoverDelay.restart();
                }
            } else {
                hoverDelay.stop();
                leaveDelay.restart();
            }
        }

        onClicked: {
            hoverDelay.stop();
            root.dismissPopup();
            if (toplevels.length === 0) {
                desktopEntry?.execute();
            } else if (toplevels.length > 1) {
                root.menuButton = button;
            } else {
                HyprlandData.focusWindow(root.addressOf(toplevels[0]));
            }
        }
        middleClickAction: () => desktopEntry?.execute()
        altAction: () => {
            hoverDelay.stop();
            root.menuButton = root.menuButton === button ? null : button;
        }

        AppIcon {
            anchors.centerIn: parent
            implicitSize: root.buttonSize * 0.55
            source: AppSearch.guessIcon(button.appEntry.appId)
        }

        Rectangle {
            visible: button.toplevels.length > 0
            anchors {
                horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
                verticalCenter: root.vertical ? parent.verticalCenter : undefined
                bottom: !root.vertical && BarOptions.bottom ? parent.bottom : undefined
                top: !root.vertical && !BarOptions.bottom ? parent.top : undefined
                right: root.vertical && BarOptions.bottom ? parent.right : undefined
                left: root.vertical && !BarOptions.bottom ? parent.left : undefined
                margins: 2
            }
            implicitWidth: root.vertical ? 3 : (button.active ? 16 : 6)
            implicitHeight: root.vertical ? (button.active ? 16 : 6) : 3
            radius: 2
            color: button.active ? Appearance.colors.colPrimary : Appearance.colors.colOutline
            Behavior on implicitWidth {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on implicitHeight {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    PopupWindow {
        id: popup
        readonly property Item target: root.popupButton
        property Item shownTarget: null
        readonly property var appEntry: shownTarget?.appEntry ?? null
        readonly property var desktopEntry: shownTarget?.desktopEntry ?? null

        onTargetChanged: {
            if (target) {
                shownTarget = target;
                anchor.updateAnchor();
            }
        }

        visible: background.opacity > 0
        color: "transparent"
        implicitWidth: popupArea.implicitWidth
        implicitHeight: popupArea.implicitHeight
        anchor {
            item: popup.shownTarget
            edges: root.vertical ? (BarOptions.bottom ? Edges.Left : Edges.Right) : (BarOptions.bottom ? Edges.Top : Edges.Bottom)
            gravity: root.vertical ? (BarOptions.bottom ? Edges.Left : Edges.Right) : (BarOptions.bottom ? Edges.Top : Edges.Bottom)
            adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
        }

        MouseArea {
            id: popupArea
            anchors.fill: parent
            implicitWidth: background.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: background.implicitHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            onContainsMouseChanged: {
                if (containsMouse)
                    leaveDelay.stop();
                else if (root.menuButton === null)
                    leaveDelay.restart();
            }

            StyledRectangularShadow {
                target: background
                opacity: background.opacity
            }
            Rectangle {
                id: background
                anchors.centerIn: parent
                readonly property real padding: 6
                implicitWidth: content.implicitWidth + padding * 2
                implicitHeight: content.implicitHeight + padding * 2
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainer
                opacity: root.popupButton !== null ? 1 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                ColumnLayout {
                    id: content
                    anchors.centerIn: parent
                    spacing: 4

                    RowLayout {
                        Layout.margins: 4
                        spacing: 8
                        AppIcon {
                            implicitSize: 18
                            source: AppSearch.guessIcon(popup.appEntry?.appId ?? "")
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: popup.desktopEntry?.name ?? popup.appEntry?.appId ?? ""
                            color: Appearance.m3colors.m3onSurface
                        }
                    }

                    RowLayout {
                        visible: (popup.appEntry?.toplevels.length ?? 0) > 0
                        spacing: 4
                        Repeater {
                            model: ScriptModel {
                                values: popup.appEntry?.toplevels ?? []
                            }
                            delegate: RippleButton {
                                id: windowCard
                                required property var modelData
                                readonly property string address: root.addressOf(modelData)
                                buttonRadius: Appearance.rounding.small
                                colBackground: modelData.activated ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                padding: 6
                                onClicked: {
                                    root.dismissPopup();
                                    HyprlandData.focusWindow(windowCard.address);
                                }
                                middleClickAction: () => windowCard.modelData.close()

                                contentItem: ColumnLayout {
                                    spacing: 4
                                    RowLayout {
                                        Layout.preferredWidth: preview.width
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: windowCard.modelData.title
                                            elide: Text.ElideRight
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        RippleButton {
                                            implicitWidth: 22
                                            implicitHeight: 22
                                            buttonRadius: Appearance.rounding.full
                                            onClicked: windowCard.modelData.close()
                                            contentItem: MaterialSymbol {
                                                horizontalAlignment: Text.AlignHCenter
                                                text: "close"
                                                iconSize: Appearance.font.pixelSize.normal
                                                color: Appearance.m3colors.m3onSurface
                                            }
                                        }
                                    }
                                    ScreencopyView {
                                        id: preview
                                        captureSource: popup.visible ? windowCard.modelData : null
                                        live: true
                                        constraintSize: Qt.size(220, 130)
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 4
                        PopupAction {
                            visible: popup.desktopEntry !== null
                            symbol: "open_in_new"
                            label: Translation.tr("New window")
                            onClicked: popup.desktopEntry?.execute()
                        }
                        PopupAction {
                            symbol: TaskbarApps.isPinned(popup.appEntry?.appId ?? "") ? "keep_off" : "keep"
                            label: TaskbarApps.isPinned(popup.appEntry?.appId ?? "") ? Translation.tr("Unpin") : Translation.tr("Pin")
                            onClicked: TaskbarApps.togglePin(popup.appEntry.appId)
                        }
                        PopupAction {
                            visible: (popup.appEntry?.toplevels.length ?? 0) > 0
                            symbol: "close"
                            label: (popup.appEntry?.toplevels.length ?? 0) > 1 ? Translation.tr("Close all") : Translation.tr("Close")
                            onClicked: popup.appEntry.toplevels.forEach(t => t.close())
                        }
                    }
                }
            }
        }
    }

    component PopupAction: RippleButtonWithIcon {
        id: action
        required property string symbol
        required property string label
        materialIcon: symbol
        mainText: label
        implicitHeight: 30
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
        colBackgroundHover: Appearance.colors.colLayer1Hover
        onClicked: root.dismissPopup()
    }
}
