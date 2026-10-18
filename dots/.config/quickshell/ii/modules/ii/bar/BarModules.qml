pragma Singleton
import QtQuick
import Quickshell
import qs.services
// Registers the dirs of modules that are only loaded by URL, so same-dir types resolve
import qs.modules.ii.bar.vertical as VerticalModules
import qs.modules.ii.bar.weather as WeatherModules

Singleton {
    id: root

    readonly property list<var> list: [
        { id: "leftSidebarButton", name: Translation.tr("Left sidebar button"), icon: "left_panel_open", file: "LeftSidebarButton.qml", framed: true },
        { id: "activeWindow", name: Translation.tr("Active window"), icon: "select_window_2", file: "ActiveWindow.qml" },
        { id: "resources", name: Translation.tr("Resources"), icon: "memory", file: "Resources.qml", verticalFile: "vertical/VerticalResources.qml", tone: "tertiary" },
        { id: "media", name: Translation.tr("Media"), icon: "music_note", file: "Media.qml", verticalFile: "vertical/VerticalMedia.qml", tone: "secondary" },
        { id: "workspaces", name: Translation.tr("Workspaces"), icon: "workspaces", file: "Workspaces.qml", framed: true },
        { id: "clock", name: Translation.tr("Clock"), icon: "schedule", file: "ClockWidget.qml", verticalFile: "vertical/VerticalClockWidget.qml", tone: "primary" },
        { id: "utilButtons", name: Translation.tr("Utility buttons"), icon: "widgets", file: "UtilButtons.qml", tone: "primary", framed: true },
        { id: "battery", name: Translation.tr("Battery"), icon: "battery_android_full", file: "BatteryIndicator.qml", verticalFile: "vertical/VerticalBatteryIndicator.qml", tone: "primary" },
        { id: "sysTray", name: Translation.tr("Tray"), icon: "shelf_auto_hide", file: "SysTray.qml", tone: "secondary" },
        { id: "systemIndicators", name: Translation.tr("System indicators"), icon: "wifi", file: "SystemIndicators.qml", tone: "primary", framed: true },
        { id: "weather", name: Translation.tr("Weather"), icon: "cloud", file: "weather/WeatherBar.qml", tone: "tertiary" }
    ]

    function byId(id) {
        return root.list.find(m => m.id === id) ?? null;
    }

    function fileFor(id, vertical) {
        const entry = root.byId(id);
        if (!entry)
            return "";
        return Qt.resolvedUrl((vertical && entry.verticalFile) ? entry.verticalFile : entry.file);
    }
}
