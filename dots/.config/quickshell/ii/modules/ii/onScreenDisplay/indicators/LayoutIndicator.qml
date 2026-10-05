import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    icon: "keyboard"
    name: Translation.tr("Keyboard Layout")
    valueText: HyprlandXkb.currentLayoutName
    showProgressBar: false
    stackNameValue: true
    value: 0
}
