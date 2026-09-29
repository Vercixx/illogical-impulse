import QtQuick
import QtQuick.Layouts

MaterialTextArea {
    id: root
    property var value: []
    signal edited(var list)

    Layout.fillWidth: true
    wrapMode: TextEdit.Wrap
    text: (root.value ?? []).join(", ")
    onEditingFinished: root.edited(text.split(",").map(s => s.trim()).filter(s => s.length > 0))
}
