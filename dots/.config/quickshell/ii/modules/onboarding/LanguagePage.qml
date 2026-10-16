pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

OnboardingPage {
    id: root
    icon: "language"
    title: Translation.tr("Choose your language")
    showBack: false
    contentWidth: 720

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        uniformCellWidths: true
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: ["auto", ...Translation.allAvailableLanguages]
            delegate: RippleButton {
                id: languageButton
                required property string modelData
                readonly property var name: modelData === "auto" ? {
                    "native": Translation.tr("Auto (System)"),
                    "english": Translation.languageName(Qt.locale().name).english
                } : Translation.languageName(modelData)
                Layout.fillWidth: true
                implicitHeight: 56
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer1
                toggled: Config.options.language.ui === modelData
                onClicked: Config.options.language.ui = modelData

                contentItem: ColumnLayout {
                    spacing: 0
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        text: languageButton.name.native
                        color: languageButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        elide: Text.ElideRight
                        text: languageButton.name.english
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: languageButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
