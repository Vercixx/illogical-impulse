import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common

// Loads one bar module and hands it this object as `host` for bar context.
Item {
    id: root
    required property string modelData
    required property int index
    required property var group

    readonly property string moduleId: modelData
    readonly property var bar: group.bar
    readonly property var traits: Appearance.barStyle
    readonly property bool vertical: Config.options.bar.vertical
    readonly property int shortenLevel: bar.shortenLevel
    readonly property bool sideHovered: group.section.sideHovered
    readonly property bool segmented: traits.groups === "connected"
    readonly property bool tonal: traits.groups === "tonal" && group.tone !== ""
    readonly property color colForeground: tonal ? Appearance.colors[`colOn${group.toneName}Container`] : Appearance.colors.colOnLayer1
    readonly property color colAccent: tonal ? colForeground : Appearance.colors.colOnSecondaryContainer
    readonly property bool available: loader.item !== null && (loader.item.available ?? true)
    readonly property bool fills: loader.item?.fillsSpace ?? false
    // Framed modules draw their own button background, which already sits at the content inset
    readonly property real padding: (segmented ? 5 : 0) + (BarModules.byId(moduleId)?.framed ? 0 : 5)
    readonly property Item neck: segmented ? root : group
    readonly property bool drawerOpen: {
        const drawer = root.QsWindow.window?.activeDrawer;
        return !!drawer && drawer.open && drawer.neck === root;
    }

    visible: available
    Layout.fillWidth: vertical || fills
    Layout.fillHeight: !vertical
    implicitWidth: (loader.item?.implicitWidth ?? 0) + (vertical ? 0 : padding * 2)
    implicitHeight: (loader.item?.implicitHeight ?? 0) + (vertical ? padding * 2 : 0)

    function load() {
        loader.setSource(BarModules.fileFor(root.moduleId, root.vertical), { host: root });
    }
    Component.onCompleted: load()
    onVerticalChanged: load()

    BarPill {
        id: segment
        visible: root.segmented
        drawerOpen: root.drawerOpen
        baseColor: root.bar.traits.strip ? Appearance.colors.colLayer1 : Appearance.colors.colLayer1Base
        startRadius: root.group.firstShownIndex === root.index ? Appearance.rounding.full : Appearance.rounding.unsharpenmore
        endRadius: root.group.lastShownIndex === root.index ? Appearance.rounding.full : Appearance.rounding.unsharpenmore
    }

    Loader {
        id: loader
        anchors.centerIn: root.fills ? undefined : parent
        anchors.fill: root.fills ? parent : undefined
        anchors.leftMargin: root.vertical ? 0 : root.padding
        anchors.rightMargin: root.vertical ? 0 : root.padding
        anchors.topMargin: root.vertical ? root.padding : 0
        anchors.bottomMargin: root.vertical ? root.padding : 0
    }
}
