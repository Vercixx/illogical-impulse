import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    component AppCommandField: MaterialTextArea {
        required property string key
        Layout.fillWidth: true
        wrapMode: TextEdit.Wrap
        text: Config.options.apps[key]
        onTextChanged: Config.options.apps[key] = text
    }

    ContentSection {
        icon: "apps"
        title: Translation.tr("Default apps")

        AppCommandField {
            key: "terminal"
            placeholderText: Translation.tr("Terminal")
        }
        AppCommandField {
            key: "taskManager"
            placeholderText: Translation.tr("Task manager")
        }
        AppCommandField {
            key: "volumeMixer"
            placeholderText: Translation.tr("Volume mixer")
        }
        AppCommandField {
            key: "update"
            placeholderText: Translation.tr("System update")
        }
    }

    ContentSection {
        icon: "settings_applications"
        title: Translation.tr("System settings")

        AppCommandField {
            key: "network"
            placeholderText: Translation.tr("Network")
        }
        AppCommandField {
            key: "networkEthernet"
            placeholderText: Translation.tr("Ethernet")
        }
        AppCommandField {
            key: "bluetooth"
            placeholderText: Translation.tr("Bluetooth")
        }
        AppCommandField {
            key: "manageUser"
            placeholderText: Translation.tr("User accounts")
        }
        AppCommandField {
            key: "changePassword"
            placeholderText: Translation.tr("Change password")
        }
    }
}
