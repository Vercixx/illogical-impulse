import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.common.widgets

ConfigSwitch {
    id: root
    required property string key

    Binding on checked {
        value: !!option.shownValue
    }
    onClicked: HyprlandConfig.setUser(root.key, option.shownValue ? "false" : "true")

    HyprlandConfigOption {
        id: option
        key: root.key
    }
}
