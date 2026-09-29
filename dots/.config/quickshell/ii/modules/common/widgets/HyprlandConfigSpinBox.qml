import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.common.widgets

ConfigSpinBox {
    id: root
    required property string key

    Binding on value {
        value: typeof option.shownValue === "string" ? root.parseCss(option.shownValue) : (option.shownValue ?? 0)
    }
    onValueModified: writeTimer.restart()

    // same num repeated 4 times = same gaps on all sides
    function parseCss(css: string): int {
        const side = css.slice(0, css.length / 4);
        return side.repeat(4) === css ? parseInt(side) : parseInt(css);
    }

    HyprlandConfigOption {
        id: option
        key: root.key
    }

    Timer {
        id: writeTimer
        interval: 400
        onTriggered: HyprlandConfig.setUser(root.key, root.value)
    }
}
