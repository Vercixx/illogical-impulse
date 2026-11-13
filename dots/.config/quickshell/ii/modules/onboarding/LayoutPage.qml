import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

OnboardingPage {
    id: root
    readonly property var layouts: [
        { "value": "dwindle", "displayName": Translation.tr("Dwindle"), "description": Translation.tr("Uses binary space partitioning to recursively divide your workspace between windows") },
        { "value": "master", "displayName": Translation.tr("Master"), "description": Translation.tr("Dedicates one half of your screen to one window while keeping other ones stacked beside it") },
        { "value": "scrolling", "displayName": Translation.tr("Scrolling"), "description": Translation.tr("Stacks your windows in columns on an infinitely growing tape") },
        { "value": "monocle", "displayName": Translation.tr("Monocle"), "description": Translation.tr("Displays one window at a time, maximizing your available workspace") },
        { "value": "lua:drift", "displayName": Translation.tr("Drift"), "description": Translation.tr("Gets rid of tiling in favor of an infinite 2D canvas your windows can use") }
    ]
    readonly property var shownLayout: root.layouts.find(l => l.value === layoutOption.shownValue) ?? root.layouts[0]

    icon: "view_quilt"
    title: Translation.tr("Pick a layout")
    description: Translation.tr("A layout decides how to place windows. You can change it later in Settings.")

    HyprlandConfigOption {
        id: layoutOption
        key: "general:layout"
    }

    LayoutDemo {
        Layout.alignment: Qt.AlignHCenter
        layout: root.shownLayout.value
    }

    ConfigSelectionArray {
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignHCenter
        currentValue: root.shownLayout.value
        onSelected: newValue => HyprlandConfig.setUser("general:layout", newValue)
        options: root.layouts
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: root.shownLayout.description
        color: Appearance.colors.colSubtext
    }
}
