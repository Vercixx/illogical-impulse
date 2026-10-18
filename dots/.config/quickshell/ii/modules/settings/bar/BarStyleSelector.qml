import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ConfigSelectionArray {
    currentValue: Config.options.bar.style
    onSelected: newValue => Config.options.bar.style = newValue
    options: [
        { displayName: Translation.tr("Hug"), icon: "line_curve", value: "hug" },
        { displayName: Translation.tr("Float"), icon: "page_header", value: "float" },
        { displayName: Translation.tr("Rect"), icon: "toolbar", value: "rect" },
        { displayName: Translation.tr("Minimal"), icon: "split_scene", value: "minimal" },
        { displayName: Translation.tr("Connected groups"), icon: "view_column_2", value: "connected" },
        { displayName: Translation.tr("Islands"), icon: "location_chip", value: "islands" },
        { displayName: Translation.tr("M3 Tonal"), icon: "interests", value: "tonal" },
        { displayName: Translation.tr("M3 Tabs"), icon: "tab", value: "tabs" }
    ]
}
