import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    required property string edge // start | center | end
    required property var groups
    required property var bar
    property bool sideHovered: false
    property real maximumLength: Infinity

    readonly property var traits: Appearance.barStyle
    readonly property bool vertical: Config.options.bar.vertical
    readonly property bool innerIsStart: Config.options.bar.bottom
    readonly property bool tabs: traits.sections === "tabs"
    readonly property bool hasContainer: traits.sections !== "none"
    readonly property real containerPadding: 4
    readonly property real outerPadding: edge === "center" ? (hasContainer ? containerPadding : 0) : (traits.sections === "round" ? containerPadding : Appearance.rounding.screenRounding)
    readonly property real startPadding: edge === "end" ? (hasContainer ? containerPadding : 0) : outerPadding
    readonly property real endPadding: edge === "start" ? (hasContainer ? containerPadding : 0) : outerPadding
    readonly property real length: Math.min(layout.implicitLength + startPadding + endPadding, maximumLength)

    // JSON round trip so a config reload with the same layout doesn't rebuild every module
    readonly property string groupsKey: JSON.stringify(groups ?? [])
    readonly property var groupList: JSON.parse(groupsKey).filter(g => Array.isArray(g) && g.length > 0)

    readonly property int firstShownIndex: {
        repeater.count;
        for (let i = 0; i < repeater.count; i++) {
            if (repeater.itemAt(i)?.shown)
                return i;
        }
        return -1;
    }

    visible: firstShownIndex >= 0
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : length
    implicitHeight: vertical ? length : Appearance.sizes.baseBarHeight

    Loader {
        active: root.traits.sections === "round"
        anchors.fill: parent
        sourceComponent: Item {
            StyledRectangularShadow {
                target: roundContainer
            }
            Rectangle {
                id: roundContainer
                anchors.fill: parent
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer0Base
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
            }
        }
    }

    Loader {
        active: root.tabs
        anchors.fill: parent
        sourceComponent: Item {
            readonly property real cornerSize: Appearance.rounding.screenRounding
            readonly property bool touchesStart: root.edge === "start"
            readonly property bool touchesEnd: root.edge === "end"

            Rectangle {
                id: tab
                anchors.fill: parent
                color: Appearance.colors.colLayer0Base
                readonly property real r: parent.cornerSize
                topLeftRadius: (root.vertical ? (root.innerIsStart && !parent.touchesStart) : (root.innerIsStart && !parent.touchesStart)) ? r : 0
                topRightRadius: (root.vertical ? (!root.innerIsStart && !parent.touchesStart) : (root.innerIsStart && !parent.touchesEnd)) ? r : 0
                bottomLeftRadius: (root.vertical ? (root.innerIsStart && !parent.touchesEnd) : (!root.innerIsStart && !parent.touchesStart)) ? r : 0
                bottomRightRadius: (root.vertical ? (!root.innerIsStart && !parent.touchesEnd) : (!root.innerIsStart && !parent.touchesEnd)) ? r : 0
            }
            RoundCorner {
                visible: !parent.touchesStart
                implicitSize: parent.cornerSize
                color: tab.color
                x: root.vertical ? (root.innerIsStart ? parent.width - implicitSize : 0) : -implicitSize
                y: root.vertical ? -implicitSize : (root.innerIsStart ? parent.height - implicitSize : 0)
                corner: root.vertical ? (root.innerIsStart ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.BottomLeft) : (root.innerIsStart ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight)
            }
            RoundCorner {
                visible: !parent.touchesEnd
                implicitSize: parent.cornerSize
                color: tab.color
                x: root.vertical ? (root.innerIsStart ? parent.width - implicitSize : 0) : parent.width
                y: root.vertical ? parent.height : (root.innerIsStart ? parent.height - implicitSize : 0)
                corner: root.vertical ? (root.innerIsStart ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.TopLeft) : (root.innerIsStart ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft)
            }
        }
    }

    BoxLayout {
        id: layout
        readonly property real implicitLength: root.vertical ? implicitHeight : implicitWidth
        vertical: root.vertical
        spacing: 4
        anchors {
            fill: parent
            leftMargin: root.vertical ? 0 : root.startPadding
            rightMargin: root.vertical ? 0 : root.endPadding
            topMargin: root.vertical ? root.startPadding : 0
            bottomMargin: root.vertical ? root.endPadding : 0
        }

        Repeater {
            id: repeater
            model: root.groupList
            delegate: BoxLayout {
                id: groupSlot
                required property var modelData
                required property int index
                readonly property bool shown: group.shown
                visible: shown
                vertical: root.vertical
                spacing: 4
                Layout.fillWidth: group.Layout.fillWidth
                Layout.fillHeight: root.vertical ? false : true

                Rectangle {
                    visible: root.traits.groups === "line" && groupSlot.index > root.firstShownIndex
                    Layout.fillHeight: !root.vertical
                    Layout.fillWidth: root.vertical
                    Layout.topMargin: root.vertical ? 0 : Appearance.sizes.baseBarHeight / 3
                    Layout.bottomMargin: root.vertical ? 0 : Appearance.sizes.baseBarHeight / 3
                    Layout.leftMargin: root.vertical ? Appearance.sizes.baseVerticalBarWidth / 3 : 0
                    Layout.rightMargin: root.vertical ? Appearance.sizes.baseVerticalBarWidth / 3 : 0
                    implicitWidth: 1
                    implicitHeight: 1
                    color: Appearance.colors.colOutlineVariant
                }

                BarGroup {
                    id: group
                    modelData: groupSlot.modelData
                    section: root
                }
            }
        }
    }
}
