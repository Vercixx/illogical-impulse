import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root
    property var keys: []
    spacing: 3

    Repeater {
        model: root.keys
        delegate: RowLayout {
            id: keyRow
            required property string modelData
            required property int index
            spacing: 3

            StyledText {
                visible: keyRow.index > 0
                Layout.alignment: Qt.AlignVCenter
                text: "+"
            }
            KeyboardKey {
                key: keyRow.modelData === "Super" ? (Config.options.cheatsheet.superKey || "󰖳") : keyRow.modelData
            }
        }
    }
}
