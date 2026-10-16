import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property string icon
    property string title
    property string description
    property string nextText: Translation.tr("Next")
    property bool showBack: true
    property real contentWidth: 640
    readonly property Item maskItem: root
    default property alias contentData: contentColumn.data

    signal next
    signal back

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(root.width - 80, root.contentWidth)
        spacing: 24

        MaterialShapeWrappedMaterialSymbol {
            visible: root.icon !== ""
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            padding: 14
            iconSize: 56
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.title
                color: Appearance.colors.colOnLayer0
                font {
                    family: Appearance.font.family.title
                    pixelSize: 32
                    variableAxes: Appearance.font.variableAxes.title
                }
            }
            StyledText {
                visible: root.description !== ""
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.description
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            spacing: 8

            OnboardingButton {
                visible: root.showBack
                primary: false
                buttonText: Translation.tr("Back")
                onClicked: root.back()
            }
            OnboardingButton {
                buttonText: root.nextText
                onClicked: root.next()
            }
        }
    }
}
