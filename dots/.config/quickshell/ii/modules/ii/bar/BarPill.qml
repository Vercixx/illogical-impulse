import QtQuick
import qs.modules.common

// Group or segment background; while a drawer is open it reaches the bar's inner edge and becomes the drawer's neck.
Rectangle {
    id: root
    property bool drawerOpen: false
    property color baseColor: "transparent"
    property real startRadius: Appearance.rounding.small
    property real endRadius: Appearance.rounding.small
    property real inset: 4

    readonly property bool vertical: Config.options.bar.vertical
    readonly property bool innerIsStart: Config.options.bar.bottom
    readonly property real innerInset: drawerOpen ? 0 : inset

    anchors {
        fill: parent
        topMargin: root.vertical ? 0 : (root.innerIsStart ? root.innerInset : root.inset)
        bottomMargin: root.vertical ? 0 : (root.innerIsStart ? root.inset : root.innerInset)
        leftMargin: root.vertical ? (root.innerIsStart ? root.innerInset : root.inset) : 0
        rightMargin: root.vertical ? (root.innerIsStart ? root.inset : root.innerInset) : 0
    }
    color: drawerOpen ? Appearance.m3colors.m3surfaceContainer : baseColor

    function cornerRadius(alongStart, onInnerSide) {
        if (onInnerSide && root.drawerOpen)
            return 0;
        return alongStart ? root.startRadius : root.endRadius;
    }
    topLeftRadius: cornerRadius(true, innerIsStart)
    topRightRadius: cornerRadius(vertical, vertical ? !innerIsStart : innerIsStart)
    bottomLeftRadius: cornerRadius(!vertical, vertical ? innerIsStart : !innerIsStart)
    bottomRightRadius: cornerRadius(false, !innerIsStart)

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    Behavior on anchors.topMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on anchors.bottomMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on anchors.leftMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on anchors.rightMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on topLeftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on topRightRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on bottomLeftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on bottomRightRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
