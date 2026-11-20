pragma Singleton
import QtQuick
import Quickshell

// Bar position and layout in effect: the user's bar settings, or the fixed taskbar of the classic panel family
Singleton {
    readonly property bool taskbar: Config.options.panelFamily === "classic"
    readonly property bool bottom: taskbar || Config.options.bar.bottom
    readonly property bool vertical: !taskbar && Config.options.bar.vertical
    readonly property var layout: taskbar ? ({
            left: [["start"], ["tasks"]],
            center: [],
            right: [["sysTray"], ["systemIndicators"], ["clock"]],
            centerAnchor: "",
            centerAnchorGroup: false
        }) : Config.options.bar.layout
}
