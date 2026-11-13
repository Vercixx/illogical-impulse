import qs.modules.common
import QtQuick

Rectangle {
    id: root
    property int slot

    implicitWidth: content.implicitWidth + 12
    implicitHeight: content.implicitHeight + 6
    radius: Appearance.rounding.full
    color: Appearance.colors.colSecondaryContainer

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 2
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: "bookmark"
            fill: 1
            iconSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSecondaryContainer
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.slot
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
}
