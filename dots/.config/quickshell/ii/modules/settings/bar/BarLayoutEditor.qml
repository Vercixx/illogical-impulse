pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.bar

// Drag modules, or whole groups by their handle, between sections; drop on Available to remove; click a module for its options
Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    readonly property bool vertical: Config.options.bar.vertical
    readonly property var layoutConfig: Config.options.bar.layout
    readonly property var lanes: [
        { key: "left", title: vertical ? Translation.tr("Top") : Translation.tr("Left") },
        { key: "center", title: Translation.tr("Center") },
        { key: "right", title: vertical ? Translation.tr("Bottom") : Translation.tr("Right") }
    ]
    readonly property var usedIds: ["left", "center", "right"].reduce((ids, key) => ids.concat(...laneCopy(key)), [])
    readonly property var unusedModules: BarModules.list.filter(m => !usedIds.includes(m.id))

    readonly property int rowHeight: 28
    readonly property int groupPadding: 2
    readonly property int groupGap: 4
    readonly property int lanePadding: 6
    readonly property int handleWidth: 26
    readonly property int edgeBand: 8
    readonly property int draggedRows: dragging?.ids.length ?? 1

    property var dragging: null // { ids, lane, group, index }; index -1 = whole group, lane "" = Available
    property var target: null // { lane, group, index } into a group, { lane, group, newGroup } before a group (-1 = end), or { remove }
    property var snapshot: null

    BarModuleSettings {
        id: moduleSettings
    }

    function laneCopy(key) {
        return JSON.parse(JSON.stringify(Config.options.bar.layout[key] ?? []));
    }

    function drop(target) {
        const d = root.dragging;
        root.dragging = null;
        root.target = null;
        if (!d)
            return;
        const layout = Config.options.bar.layout;
        const lists = { left: laneCopy("left"), center: laneCopy("center"), right: laneCopy("right") };
        const source = d.lane !== "" ? lists[d.lane][d.group] : [];
        const sourceIds = source.slice();
        if (d.index < 0)
            source.fill(null);
        else
            source[d.index] = null;
        if (target) {
            const lane = lists[target.lane];
            if (target.newGroup)
                lane.splice(target.group < 0 ? lane.length : target.group, 0, d.ids.slice());
            else
                lane[target.group].splice(target.index < 0 ? lane[target.group].length : target.index, 0, ...d.ids);
        }
        for (const key in lists) {
            lists[key] = lists[key].map(g => g.filter(id => id !== null)).filter(g => g.length > 0);
            if (JSON.stringify(lists[key]) !== JSON.stringify(layout[key]))
                layout[key] = lists[key];
        }

        let anchor = layout.centerAnchor;
        if (layout.centerAnchorGroup && d.index >= 0 && d.ids[0] === anchor)
            anchor = sourceIds.find(id => id !== anchor) ?? anchor;
        if (!lists.center.some(g => g.includes(anchor)))
            anchor = "";
        if (anchor !== layout.centerAnchor)
            layout.centerAnchor = anchor;
    }

    function remove(id, lane, group, index) {
        root.dragging = { ids: [id], lane: lane, group: group, index: index };
        root.drop(null);
    }

    function anchorsModule(id, groupSize) {
        return root.layoutConfig.centerAnchor === id && (!root.layoutConfig.centerAnchorGroup || groupSize === 1);
    }

    function anchorsGroup(modules) {
        return root.layoutConfig.centerAnchorGroup && modules.includes(root.layoutConfig.centerAnchor);
    }

    function setAnchor(id, wholeGroup) {
        Config.options.bar.layout.centerAnchor = id;
        Config.options.bar.layout.centerAnchorGroup = wholeGroup;
    }

    // Targets come from geometry frozen at drag start with the dragged item already collapsed, so placeholders can't feed back
    function takeSnapshot(d) {
        const shot = { lanes: [], groups: [], rows: [], available: null };
        let cut = null;
        const rectOf = item => {
            const p = item.mapToItem(root, 0, 0);
            return { x: p.x, y: p.y, width: item.width, height: item.height };
        };
        const walk = item => {
            for (const child of item.children) {
                const source = d.lane !== "" && child.lane === d.lane;
                if (child.editorRole === "lane") {
                    shot.lanes.push({ key: child.laneKey, rect: rectOf(child) });
                } else if (child.editorRole === "group") {
                    const rect = rectOf(child);
                    if (source && child.groupIndex === d.group && (d.index < 0 || child.size === 1))
                        cut = { y: rect.y + rect.height + root.groupGap, height: rect.height + root.groupGap };
                    else
                        shot.groups.push({ lane: child.lane, index: child.groupIndex, rect: rect });
                } else if (child.editorRole === "row" && child.lane !== "") {
                    const rect = rectOf(child);
                    if (source && child.slotGroup === d.group && child.slotIndex === d.index)
                        cut = cut ?? { y: rect.y + rect.height, height: rect.height };
                    else
                        shot.rows.push({ lane: child.lane, group: child.slotGroup, index: child.slotIndex, rect: rect });
                } else if (child.editorRole === "available") {
                    shot.available = rectOf(child);
                }
                walk(child);
            }
        };
        walk(column);
        if (cut) {
            const rects = [shot.available].concat(shot.lanes.map(l => l.rect), shot.groups.map(g => g.rect), shot.rows.map(r => r.rect));
            for (const rect of rects) {
                if (rect.y >= cut.y - 0.5)
                    rect.y -= cut.height;
                else if (rect.y + rect.height > cut.y - 0.5)
                    rect.height -= cut.height;
            }
        }
        shot.groups.sort((a, b) => a.index - b.index);
        shot.rows.sort((a, b) => a.index - b.index);
        root.snapshot = shot;
    }

    function contains(rect, p) {
        return !!rect && p.x >= rect.x && p.x <= rect.x + rect.width && p.y >= rect.y && p.y <= rect.y + rect.height;
    }

    function targetAt(p) {
        const shot = root.snapshot;
        if (!shot)
            return null;
        if (contains(shot.available, p))
            return { remove: true };
        const lane = shot.lanes.find(l => contains(l.rect, p));
        if (!lane)
            return null;
        for (const group of shot.groups.filter(g => g.lane === lane.key)) {
            if (p.y < group.rect.y + root.edgeBand)
                return { lane: lane.key, group: group.index, newGroup: true };
            if (p.y > group.rect.y + group.rect.height - root.edgeBand)
                continue;
            const before = shot.rows.find(r => r.lane === lane.key && r.group === group.index && p.y < r.rect.y + r.rect.height / 2);
            return { lane: lane.key, group: group.index, index: before ? before.index : -1 };
        }
        return { lane: lane.key, group: -1, newGroup: true };
    }

    function updateTarget() {
        if (!root.dragging)
            return;
        const t = root.targetAt(Qt.point(ghost.x + 20, ghost.y + root.groupPadding + root.rowHeight / 2));
        if (JSON.stringify(t) !== JSON.stringify(root.target))
            root.target = t;
    }

    function placeGhost(item, mouse, ids) {
        const p = item.mapToItem(root, mouse.x, mouse.y);
        ghost.ids = ids;
        ghost.x = Math.round(p.x - 20);
        ghost.y = Math.round(p.y - root.groupPadding - root.rowHeight / 2);
    }

    function startDrag(ids, lane, group, index) {
        const d = { ids: ids, lane: lane, group: group, index: index };
        root.takeSnapshot(d);
        root.dragging = d;
        root.updateTarget();
    }

    function endDrag() {
        const t = root.target;
        if (!t) {
            root.dragging = null;
            return;
        }
        root.drop(t.remove ? null : t);
    }

    function targetsInto(lane, group, index) {
        const t = root.target;
        return !!t && !t.remove && !t.newGroup && t.lane === lane && t.group === group && t.index === index;
    }

    function targetsNewGroup(lane, group) {
        const t = root.target;
        return !!t && !!t.newGroup && t.lane === lane && t.group === group;
    }

    function drags(lane, group, index) {
        const d = root.dragging;
        return !!d && lane !== "" && d.lane === lane && d.group === group && (d.index < 0 || d.index === index);
    }

    function emptiedByDrag(lane, group, size) {
        const d = root.dragging;
        return !!d && lane !== "" && d.lane === lane && d.group === group && (d.index < 0 || size === 1);
    }

    component Placeholder: Item {
        id: placeholder
        property bool open: false
        property int block: root.draggedRows * root.rowHeight
        property int gap: 0
        property real radius: Appearance.rounding.full
        implicitHeight: open ? block + gap : 0
        clip: true
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Rectangle {
            width: parent.width
            height: placeholder.block
            radius: placeholder.radius
            color: "transparent"
            border.width: 1
            border.color: Appearance.colors.colPrimary
            opacity: placeholder.open ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    component IconButton: RippleButton {
        id: iconButton
        property string symbol
        property string tip: ""
        implicitWidth: 24
        implicitHeight: 24
        padding: 0
        buttonRadius: Appearance.rounding.full
        colBackgroundHover: Appearance.colors.colLayer2Active
        colRipple: Appearance.colors.colLayer2Active
        contentItem: MaterialSymbol {
            text: iconButton.symbol
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconSize: Appearance.font.pixelSize.normal
            color: iconButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
        }
        StyledToolTip {
            extraVisibleCondition: iconButton.tip !== ""
            text: iconButton.tip
        }
    }

    component ModuleRow: Rectangle {
        id: row
        readonly property string editorRole: "row"
        required property string moduleId
        property string lane: ""
        property int slotGroup: -1
        property int slotIndex: -1
        property int groupSize: 1
        readonly property var info: BarModules.byId(moduleId)
        readonly property bool placed: lane !== ""
        readonly property bool hasSettings: moduleSettings.component(moduleId) !== null

        implicitWidth: rowContent.implicitWidth + 24
        implicitHeight: root.drags(lane, slotGroup, slotIndex) ? 0 : root.rowHeight
        clip: true
        radius: Appearance.rounding.full
        color: {
            if (dragArea.containsMouse && !root.dragging)
                return Appearance.colors.colLayer2Hover;
            return placed ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 1) : Appearance.colors.colLayer2;
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : (row.hasSettings ? Qt.PointingHandCursor : Qt.OpenHandCursor)
            drag.target: ghost
            drag.threshold: 4
            onPressed: mouse => root.placeGhost(row, mouse, [row.moduleId])
            onClicked: {
                if (row.hasSettings)
                    settingsDialog.moduleId = row.moduleId;
            }
            drag.onActiveChanged: {
                if (drag.active)
                    root.startDrag([row.moduleId], row.lane, row.slotGroup, row.slotIndex);
                else
                    root.endDrag();
            }
        }

        RowLayout {
            id: rowContent
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 12
                rightMargin: row.placed ? 2 : 12
            }
            height: root.rowHeight
            spacing: 8

            MaterialSymbol {
                text: row.info?.icon ?? "help"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: row.info?.name ?? row.moduleId
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer2
            }
            IconButton {
                visible: row.lane === "center"
                symbol: root.vertical ? "align_vertical_center" : "align_horizontal_center"
                toggled: root.anchorsModule(row.moduleId, row.groupSize)
                tip: Translation.tr("Keep this module in the middle of the bar")
                onClicked: root.setAnchor(toggled ? "" : row.moduleId, false)
            }
            IconButton {
                visible: row.placed
                symbol: "close"
                onClicked: root.remove(row.moduleId, row.lane, row.slotGroup, row.slotIndex)
            }
        }
    }

    component GroupBox: Item {
        id: group
        required property var modules
        required property string lane
        required property int groupIndex
        readonly property bool anchored: lane === "center" && modules.length > 1 && root.anchorsGroup(modules)

        implicitHeight: root.emptiedByDrag(lane, groupIndex, modules.length) ? 0 : box.height + root.groupGap
        clip: true
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Rectangle {
            id: box
            readonly property string editorRole: "group"
            readonly property string lane: group.lane
            readonly property int groupIndex: group.groupIndex
            readonly property int size: group.modules.length
            width: parent.width
            height: rows.implicitHeight + root.groupPadding * 2
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: group.anchored ? Appearance.colors.colPrimary : color
            Behavior on border.color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            MouseArea {
                id: handleArea
                width: root.handleWidth
                height: parent.height
                hoverEnabled: true
                preventStealing: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: ghost
                drag.threshold: 4
                onPressed: mouse => root.placeGhost(handleArea, mouse, group.modules)
                drag.onActiveChanged: {
                    if (drag.active)
                        root.startDrag(group.modules, group.lane, group.groupIndex, -1);
                    else
                        root.endDrag();
                }

                MaterialSymbol {
                    x: Math.round((parent.width - width) / 2) + 2
                    y: Math.round(root.groupPadding + (root.rowHeight - height) / 2)
                    text: "drag_indicator"
                    iconSize: Appearance.font.pixelSize.large
                    color: handleArea.containsMouse ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                }
                IconButton {
                    visible: group.lane === "center" && group.modules.length > 1
                    x: Math.round((parent.width - width) / 2) + 2
                    y: parent.height - root.groupPadding - Math.round((root.rowHeight + height) / 2)
                    symbol: root.vertical ? "align_vertical_center" : "align_horizontal_center"
                    toggled: group.anchored
                    tip: Translation.tr("Keep this group in the middle of the bar")
                    onClicked: root.setAnchor(toggled ? "" : group.modules[0], !toggled)
                }
            }

            Column {
                id: rows
                x: root.handleWidth
                y: root.groupPadding
                width: parent.width - x - root.groupPadding

                Repeater {
                    model: group.modules
                    delegate: Column {
                        id: slot
                        required property string modelData
                        required property int index
                        width: rows.width
                        Placeholder {
                            width: parent.width
                            open: root.targetsInto(group.lane, group.groupIndex, slot.index)
                        }
                        ModuleRow {
                            width: parent.width
                            moduleId: slot.modelData
                            lane: group.lane
                            slotGroup: group.groupIndex
                            slotIndex: slot.index
                            groupSize: group.modules.length
                        }
                    }
                }
                Placeholder {
                    width: parent.width
                    open: root.targetsInto(group.lane, group.groupIndex, -1)
                }
            }
        }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
            model: root.lanes
            delegate: ColumnLayout {
                id: laneColumn
                required property var modelData
                readonly property string laneKey: modelData.key
                Layout.fillWidth: true
                spacing: 4

                ContentSubsectionLabel {
                    text: laneColumn.modelData.title
                }

                Rectangle {
                    readonly property string editorRole: "lane"
                    readonly property string laneKey: laneColumn.laneKey
                    Layout.fillWidth: true
                    implicitHeight: Math.max(laneList.implicitHeight - root.groupGap, root.rowHeight + root.groupPadding * 2) + root.lanePadding * 2
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    Column {
                        id: laneList
                        x: root.lanePadding
                        y: root.lanePadding
                        width: parent.width - root.lanePadding * 2

                        Repeater {
                            model: Config.options.bar.layout[laneColumn.laneKey]
                            delegate: Column {
                                id: groupSlot
                                required property var modelData
                                required property int index
                                width: laneList.width
                                Placeholder {
                                    width: parent.width
                                    block: root.draggedRows * root.rowHeight + root.groupPadding * 2
                                    gap: root.groupGap
                                    radius: Appearance.rounding.small
                                    open: root.targetsNewGroup(laneColumn.laneKey, groupSlot.index)
                                }
                                GroupBox {
                                    width: parent.width
                                    modules: Array.from(groupSlot.modelData)
                                    lane: laneColumn.laneKey
                                    groupIndex: groupSlot.index
                                }
                            }
                        }
                        Placeholder {
                            width: parent.width
                            block: root.draggedRows * root.rowHeight + root.groupPadding * 2
                            gap: root.groupGap
                            radius: Appearance.rounding.small
                            open: root.targetsNewGroup(laneColumn.laneKey, -1)
                        }
                    }

                    StyledText {
                        x: Math.round((parent.width - width) / 2)
                        y: Math.round((parent.height - height) / 2)
                        visible: laneList.implicitHeight === 0
                        text: Translation.tr("Drop modules here")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        ContentSubsectionLabel {
            text: Translation.tr("Available")
        }

        Rectangle {
            id: availableZone
            readonly property string editorRole: "available"
            readonly property bool targeted: !!root.target?.remove && root.dragging?.lane !== ""
            Layout.fillWidth: true
            implicitHeight: Math.max(availableFlow.implicitHeight + 16, 44)
            radius: Appearance.rounding.normal
            color: "transparent"
            border.width: 1
            border.color: targeted ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
            Behavior on border.color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            Flow {
                id: availableFlow
                anchors {
                    fill: parent
                    margins: 8
                }
                spacing: 6
                move: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                Repeater {
                    model: root.unusedModules
                    delegate: ModuleRow {
                        required property var modelData
                        moduleId: modelData.id
                    }
                }
            }

            StyledText {
                x: Math.round((parent.width - width) / 2)
                y: Math.round((parent.height - height) / 2)
                visible: root.unusedModules.length === 0
                text: Translation.tr("Drop a module here to remove it")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }
    }

    Rectangle {
        id: ghost
        property var ids: []
        visible: root.dragging !== null
        z: 100
        implicitWidth: ghostColumn.implicitWidth + 24
        implicitHeight: ghostColumn.implicitHeight + root.groupPadding * 2
        radius: ids.length > 1 ? Appearance.rounding.small : Appearance.rounding.full
        color: Appearance.colors.colPrimary
        onXChanged: root.updateTarget()
        onYChanged: root.updateTarget()

        Column {
            id: ghostColumn
            x: 12
            y: root.groupPadding

            Repeater {
                model: ghost.ids
                delegate: RowLayout {
                    id: ghostRow
                    required property string modelData
                    readonly property var info: BarModules.byId(modelData)
                    height: root.rowHeight
                    spacing: 8
                    MaterialSymbol {
                        text: ghostRow.info?.icon ?? "help"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnPrimary
                    }
                    StyledText {
                        text: ghostRow.info?.name ?? ghostRow.modelData
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }

    Loader {
        id: settingsDialog
        property string moduleId: ""
        readonly property var info: BarModules.byId(moduleId)
        parent: root.Window.window?.contentItem ?? root
        z: 100
        anchors.fill: parent
        active: moduleId !== ""
        onLoaded: {
            item.show = true;
            item.forceActiveFocus();
        }

        sourceComponent: WindowDialog {
            id: dialog
            backgroundWidth: 500
            onDismiss: {
                show = false;
                closeDelay.restart();
            }

            Timer {
                id: closeDelay
                interval: Appearance.animation.elementMoveFast.duration
                onTriggered: settingsDialog.moduleId = ""
            }

            WindowDialogTitle {
                text: settingsDialog.info?.name ?? ""
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: moduleSettings.component(settingsDialog.moduleId)
            }
            WindowDialogButtonRow {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                }
                DialogButton {
                    buttonText: Translation.tr("Done")
                    onClicked: dialog.dismiss()
                }
            }
        }
    }
}
