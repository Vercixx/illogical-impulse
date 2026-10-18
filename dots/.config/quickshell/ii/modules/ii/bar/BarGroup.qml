import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    required property var modelData
    required property var section

    readonly property var modules: modelData
    readonly property var bar: section.bar
    readonly property var traits: Appearance.barStyle
    readonly property bool vertical: Config.options.bar.vertical
    readonly property string tone: modules.map(id => BarModules.byId(id)?.tone).find(t => !!t) ?? ""
    readonly property string toneName: tone.charAt(0).toUpperCase() + tone.slice(1)
    readonly property real padding: traits.groups === "connected" ? 0 : 5
    readonly property bool drawerOpen: {
        const drawer = root.QsWindow.window?.activeDrawer;
        return !!drawer && drawer.open && drawer.neck === root;
    }

    readonly property var shownIndexes: {
        repeater.count;
        const result = [];
        for (let i = 0; i < repeater.count; i++) {
            if (repeater.itemAt(i)?.available)
                result.push(i);
        }
        return result;
    }
    readonly property bool shown: shownIndexes.length > 0
    readonly property int firstShownIndex: shownIndexes[0] ?? -1
    readonly property int lastShownIndex: shownIndexes[shownIndexes.length - 1] ?? -1
    readonly property bool fills: {
        repeater.count;
        for (let i = 0; i < repeater.count; i++) {
            if (repeater.itemAt(i)?.fills)
                return true;
        }
        return false;
    }
    readonly property bool dimmed: bar.workspacesOnly && !modules.includes("workspaces")

    visible: shown
    opacity: dimmed ? 0 : 1
    enabled: !dimmed
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Layout.fillWidth: fills && !vertical
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : layout.implicitWidth + padding * 2
    implicitHeight: vertical ? layout.implicitHeight + padding * 2 : Appearance.sizes.baseBarHeight

    BarPill {
        id: background
        drawerOpen: root.drawerOpen
        baseColor: {
            switch (root.traits.groups) {
            case "pills":
                return root.traits.strip ? Appearance.colors.colLayer1 : Appearance.colors.colLayer1Base;
            case "tonal":
                return root.tone !== "" ? Appearance.colors[`col${root.toneName}Container`] : "transparent";
            default:
                return "transparent";
            }
        }
        startRadius: root.traits.groups === "tonal" ? Appearance.rounding.full : Appearance.rounding.small
        endRadius: startRadius
    }

    BoxLayout {
        id: layout
        vertical: root.vertical
        spacing: root.traits.groups === "connected" ? 2 : 4
        anchors {
            fill: parent
            leftMargin: root.vertical ? 0 : root.padding
            rightMargin: root.vertical ? 0 : root.padding
            topMargin: root.vertical ? root.padding : 0
            bottomMargin: root.vertical ? root.padding : 0
        }

        Repeater {
            id: repeater
            model: root.modules
            delegate: BarModuleHost {
                group: root
            }
        }
    }
}
