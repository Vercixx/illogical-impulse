import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings

Item {
    id: root
    readonly property Item maskItem: settingsCard

    signal next
    signal back

    StyledRectangularShadow {
        target: settingsCard
    }
    Rectangle {
        id: settingsCard
        anchors.centerIn: parent
        width: 680
        height: Math.min(parent.height - 240, 760)
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true

        ColumnLayout {
            anchors {
                fill: parent
                margins: 20
            }
            spacing: 12

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Make it yours")
                color: Appearance.colors.colOnLayer0
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                }
            }
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: Translation.tr("These settings can be changed later in Settings app.")
                color: Appearance.colors.colSubtext
            }
            QuickConfig {
                Layout.fillWidth: true
                Layout.fillHeight: true
                showMoreSettings: false
                bottomContentPadding: 20
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                OnboardingButton {
                    primary: false
                    buttonText: Translation.tr("Back")
                    onClicked: root.back()
                }
                OnboardingButton {
                    buttonText: Translation.tr("Next")
                    onClicked: root.next()
                }
            }
        }
    }
}
