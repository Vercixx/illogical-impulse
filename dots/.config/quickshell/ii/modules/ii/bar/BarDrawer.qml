pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets

// Popup that grows out of its module's group inside the bar window. Hover shows the info content, click pins it and loads `controls`.
Item {
    id: root
    visible: false

    property Item hoverTarget
    default property Item contentItem
    property Component controls: null
    property bool infoWhenPinned: true
    property bool hoverEnabled: !Config.options.bar.tooltips.clickToShow
    property bool grabFocus: true
    property bool forceOpen: false
    property bool pinned: false
    signal dismissed

    readonly property var barWindow: root.QsWindow.window
    readonly property var host: {
        for (let p = root.parent; p; p = p.parent) {
            if (p.host !== undefined)
                return p.host;
        }
        return null;
    }
    readonly property Item neck: host?.neck ?? null
    readonly property Item drawerLayer: barWindow?.drawerLayer ?? null
    readonly property bool hosted: drawerLayer !== null && neck !== null
    readonly property bool vertical: Config.options.bar.vertical
    readonly property bool atEnd: Config.options.bar.bottom

    property bool hoverShown: false
    property bool hoverSuppressed: false
    readonly property bool pointerInside: (hoverTarget?.containsMouse ?? false) || (cardLoader.item?.hovered ?? false)
    readonly property bool shown: hosted && (forceOpen || pinned || hoverShown)
    readonly property bool open: shown && barWindow.activeDrawer === root
    property bool closing: false

    readonly property Item cardItem: cardLoader.item

    function toggle() {
        if (root.pinned) {
            root.dismiss();
            root.hoverSuppressed = root.pointerInside;
            return;
        }
        root.pinned = true;
    }

    function dismiss() {
        root.pinned = false;
        root.hoverShown = false;
        root.dismissed();
    }

    onPointerInsideChanged: {
        if (!root.pointerInside) {
            root.hoverSuppressed = false;
            closeDelay.restart();
            return;
        }
        closeDelay.stop();
        if (root.hoverEnabled && !root.hoverSuppressed)
            root.hoverShown = true;
    }

    onShownChanged: {
        if (root.shown)
            root.barWindow.activeDrawer = root;
    }

    onOpenChanged: {
        if (root.open) {
            root.closing = false;
            return;
        }
        root.closing = true;
        releaseDelay.restart();
    }

    Connections {
        target: root.barWindow ?? null
        ignoreUnknownSignals: true
        function onActiveDrawerChanged() {
            if (root.shown && root.barWindow.activeDrawer !== root)
                root.dismiss();
        }
    }

    Timer {
        id: closeDelay
        interval: 200
        onTriggered: root.hoverShown = false
    }

    Timer {
        id: releaseDelay
        interval: Appearance.animation.elementResize.duration
        onTriggered: {
            root.closing = false;
            if (root.barWindow?.activeDrawer === root)
                root.barWindow.activeDrawer = null;
        }
    }

    HyprlandFocusGrab {
        active: root.grabFocus && root.pinned && root.open
        windows: [root.barWindow, root.barWindow?.drawerWindow]
        onCleared: root.dismiss()
    }

    Loader {
        id: cardLoader
        parent: root.drawerLayer
        active: root.hosted && (root.open || root.closing)
        sourceComponent: Rectangle {
            id: card
            readonly property bool hovered: cardHover.hovered
            readonly property real pad: 10
            readonly property real edgeMargin: Appearance.sizes.elevationMargin
            readonly property real flareSize: Appearance.rounding.unsharpenmore
            property bool expanded: false

            // Neck rect in bar window coordinates (the drawer layer shares that origin), refreshed every frame to follow layout shifts
            function measureNeck() {
                if (!root.neck)
                    return Qt.rect(0, 0, 0, 0);
                const p = root.neck.mapToItem(null, 0, 0);
                return Qt.rect(p.x, p.y, root.neck.width, root.neck.height);
            }
            property rect neckRect: measureNeck()
            FrameAnimation {
                running: true
                onTriggered: {
                    const r = card.measureNeck();
                    if (r.x !== card.neckRect.x || r.y !== card.neckRect.y || r.width !== card.neckRect.width || r.height !== card.neckRect.height)
                        card.neckRect = r;
                }
            }
            Component.onCompleted: expanded = Qt.binding(() => root.open)

            readonly property real neckStart: root.vertical ? neckRect.y : neckRect.x
            readonly property real neckLength: root.vertical ? neckRect.height : neckRect.width
            readonly property real innerEdge: root.vertical ? (root.atEnd ? neckRect.x : neckRect.x + neckRect.width) : (root.atEnd ? neckRect.y : neckRect.y + neckRect.height)
            readonly property real layerLength: root.vertical ? root.drawerLayer.height : root.drawerLayer.width
            readonly property real targetLength: Math.max((root.vertical ? contentColumn.implicitHeight : contentColumn.implicitWidth) + pad * 2, neckLength)
            readonly property real targetDepth: (root.vertical ? contentColumn.implicitWidth : contentColumn.implicitHeight) + pad * 2
            readonly property real targetStart: Math.max(edgeMargin, Math.min(neckStart + neckLength / 2 - targetLength / 2, layerLength - targetLength - edgeMargin))

            property real alongStart: expanded ? targetStart : neckStart
            property real alongLength: expanded ? targetLength : neckLength
            property real depth: expanded ? targetDepth : 0
            readonly property real acrossStart: root.atEnd ? innerEdge - depth : innerEdge

            x: root.vertical ? acrossStart : alongStart
            y: root.vertical ? alongStart : acrossStart
            width: root.vertical ? depth : alongLength
            height: root.vertical ? alongLength : depth

            Behavior on alongStart {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on alongLength {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on depth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small

            // Corners on the neck side shrink to the overhang so the card stays flush with a neck of the same width
            readonly property real overhangBefore: neckStart - (root.vertical ? y : x)
            readonly property real overhangAfter: (root.vertical ? y + height : x + width) - (neckStart + neckLength)
            readonly property real cornerBefore: Math.max(0, Math.min(radius, overhangBefore))
            readonly property real cornerAfter: Math.max(0, Math.min(radius, overhangAfter))
            topLeftRadius: root.vertical ? (root.atEnd ? radius : cornerBefore) : (root.atEnd ? radius : cornerBefore)
            topRightRadius: root.vertical ? (root.atEnd ? cornerBefore : radius) : (root.atEnd ? radius : cornerAfter)
            bottomLeftRadius: root.vertical ? (root.atEnd ? radius : cornerAfter) : (root.atEnd ? cornerBefore : radius)
            bottomRightRadius: root.vertical ? (root.atEnd ? cornerAfter : radius) : (root.atEnd ? cornerAfter : radius)

            Item { // Shadow, kept off the bar
                z: -1
                clip: true
                x: root.vertical ? (root.atEnd ? -card.edgeMargin * 2 : 0) : -card.edgeMargin * 2
                y: root.vertical ? -card.edgeMargin * 2 : (root.atEnd ? -card.edgeMargin * 2 : 0)
                width: card.width + card.edgeMargin * (root.vertical ? 2 : 4)
                height: card.height + card.edgeMargin * (root.vertical ? 4 : 2)
                StyledRectangularShadow {
                    target: card
                    anchors.fill: undefined
                    x: -parent.x
                    y: -parent.y
                    width: card.width
                    height: card.height
                    opacity: card.depth > 1 ? 1 : 0
                }
            }

            component Flare: RoundCorner {
                implicitSize: card.flareSize
                color: card.color
            }
            Flare {
                visible: card.overhangBefore >= implicitSize
                x: root.vertical ? (root.atEnd ? card.width : -implicitSize) : card.overhangBefore - implicitSize
                y: root.vertical ? card.overhangBefore - implicitSize : (root.atEnd ? card.height : -implicitSize)
                corner: root.vertical
                    ? (root.atEnd ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.BottomRight)
                    : (root.atEnd ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.BottomRight)
            }
            Flare {
                visible: card.overhangAfter >= implicitSize
                x: root.vertical ? (root.atEnd ? card.width : -implicitSize) : card.width - card.overhangAfter
                y: root.vertical ? card.height - card.overhangAfter : (root.atEnd ? card.height : -implicitSize)
                corner: root.vertical
                    ? (root.atEnd ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.TopRight)
                    : (root.atEnd ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.BottomLeft)
            }

            HoverHandler {
                id: cardHover
            }
            MouseArea { // Keep clicks and scrolls from reaching the bar's side areas
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onWheel: event => event.accepted = true
            }

            Item {
                anchors.fill: parent
                clip: true

                Column {
                    id: contentColumn
                    spacing: 8
                    opacity: card.expanded ? 1 : 0
                    x: root.vertical ? (root.atEnd ? parent.width - width - card.pad : card.pad) : (parent.width - width) / 2
                    y: root.vertical ? (parent.height - height) / 2 : (root.atEnd ? parent.height - height - card.pad : card.pad)

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    Item {
                        id: infoSlot
                        visible: root.infoWhenPinned || !root.pinned
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: root.contentItem?.implicitWidth ?? 0
                        implicitHeight: root.contentItem?.implicitHeight ?? 0
                        width: implicitWidth
                        height: implicitHeight
                        Component.onCompleted: {
                            if (root.contentItem)
                                root.contentItem.parent = infoSlot;
                        }
                        Component.onDestruction: {
                            if (root.contentItem)
                                root.contentItem.parent = root;
                        }
                    }

                    Loader {
                        anchors.horizontalCenter: parent.horizontalCenter
                        active: root.pinned && root.controls !== null
                        visible: active
                        sourceComponent: root.controls
                    }
                }
            }
        }
    }
}
