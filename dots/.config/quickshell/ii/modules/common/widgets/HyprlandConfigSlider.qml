import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.common.widgets

ConfigSlider {
    id: root
    required property string key

    Binding on value {
        value: option.shownValue ?? 0
    }
    onMoved: writeTimer.restart()

    HyprlandConfigOption {
        id: option
        key: root.key
    }

    Timer {
        id: writeTimer
        interval: 400
        onTriggered: HyprlandConfig.setUser(root.key, Math.round(root.value * 100) / 100)
    }
}
