pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar

// Drag chips between groups and sections, drop on Available to remove, click a chip for its options
Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    readonly property bool vertical: Config.options.bar.vertical
    readonly property var lanes: [
        { key: "left", title: vertical ? Translation.tr("Top") : Translation.tr("Left") },
        { key: "center", title: Translation.tr("Center") },
        { key: "right", title: vertical ? Translation.tr("Bottom") : Translation.tr("Right") }
    ]
    readonly property var usedIds: ["left", "center", "right"].reduce((ids, key) => ids.concat(...laneCopy(key)), [])
    readonly property var unusedModules: BarModules.list.filter(m => !usedIds.includes(m.id))

    property var dragging: null // { id, lane, group, index }; lane is "" for Available
    property var target: null // { lane, group, index } (group -1 = new group, index -1 = append) or { remove: true }
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
        const lists = { left: laneCopy("left"), center: laneCopy("center"), right: laneCopy("right") };
        if (d.lane !== "")
            lists[d.lane][d.group][d.index] = null;
        if (target) {
            const lane = lists[target.lane];
            if (target.group < 0 || target.group >= lane.length) {
                lane.push([d.id]);
            } else {
                const group = lane[target.group];
                group.splice(target.index < 0 ? group.length : target.index, 0, d.id);
            }
        }
        for (const key in lists) {
            const cleaned = lists[key].map(g => g.filter(id => id !== null)).filter(g => g.length > 0);
            if (JSON.stringify(cleaned) !== JSON.stringify(Config.options.bar.layout[key]))
                Config.options.bar.layout[key] = cleaned;
        }
    }

    function remove(lane, group, index) {
        root.dragging = { id: "", lane: lane, group: group, index: index };
        root.drop(null);
    }

    // Targets come from geometry frozen at drag start, so the reserved gaps can move things without feedback loops
    function takeSnapshot() {
        const shot = { lanes: [], groups: [], chips: [], available: null };
        const rectOf = item => {
            const p = item.mapToItem(root, 0, 0);
            return Qt.rect(p.x, p.y, item.width, item.height);
        };
        const walk = item => {
            for (const child of item.children) {
                if (child.editorRole === "lane")
                    shot.lanes.push({ key: child.laneKey, rect: rectOf(child) });
                else if (child.editorRole === "group")
                    shot.groups.push({ lane: child.laneKey, index: child.groupIndex, rect: rectOf(child) });
                else if (child.editorRole === "chip" && child.lane !== "")
                    shot.chips.push({ lane: child.lane, group: child.slotGroup, index: child.slotIndex, rect: rectOf(child) });
                else if (child.editorRole === "available")
                    shot.available = rectOf(child);
                walk(child);
            }
        };
        walk(column);
        shot.chips.sort((a, b) => a.index - b.index);
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
        const group = shot.groups.find(g => g.lane === lane.key && contains(g.rect, p));
        if (!group)
            return { lane: lane.key, group: -1, index: -1 };
        const chips = shot.chips.filter(c => c.lane === lane.key && c.group === group.index);
        const before = chips.find(c => p.x < c.rect.x + c.rect.width / 2);
        return { lane: lane.key, group: group.index, index: before ? before.index : -1 };
    }

    function targets(lane, group, index) {
        const t = root.target;
        return !!t && !t.remove && t.lane === lane && t.group === group && t.index === index;
    }

    component Placeholder: Item {
        id: placeholder
        property bool open: false
        property real gap: 4
        implicitWidth: open ? ghost.width + gap : 0
        implicitHeight: ghost.height
        clip: true
        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Rectangle {
            width: ghost.width
            height: ghost.height
            radius: Appearance.rounding.full
            color: "transparent"
            border.width: 1
            border.color: Appearance.colors.colPrimary
            opacity: placeholder.open ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    component Chip: Rectangle {
        id: chip
        readonly property string editorRole: "chip"
        required property string moduleId
        property string lane: ""
        property int slotGroup: -1
        property int slotIndex: -1
        readonly property var info: BarModules.byId(moduleId)
        readonly property bool placed: lane !== ""
        readonly property bool hasSettings: moduleSettings.component(moduleId) !== null
        readonly property bool beingDragged: root.dragging?.id === moduleId && root.dragging?.lane === lane && root.dragging?.group === slotGroup && root.dragging?.index === slotIndex
        readonly property color colContent: placed ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2

        implicitWidth: beingDragged ? 0 : chipRow.implicitWidth + 24
        implicitHeight: 32
        clip: true
        radius: Appearance.rounding.full
        color: {
            const hovered = dragArea.containsMouse && hasSettings;
            if (!placed)
                return hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2;
            return hovered ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer;
        }
        Behavior on implicitWidth {
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
            cursorShape: pressed ? Qt.ClosedHandCursor : (chip.hasSettings ? Qt.PointingHandCursor : Qt.OpenHandCursor)
            drag.target: ghost
            drag.threshold: 4
            onPressed: {
                const p = chip.mapToItem(root, 0, 0);
                ghost.x = p.x;
                ghost.y = p.y;
                ghost.moduleId = chip.moduleId;
            }
            onClicked: {
                if (chip.hasSettings)
                    settingsDialog.moduleId = chip.moduleId;
            }
            drag.onActiveChanged: {
                if (drag.active) {
                    root.takeSnapshot();
                    root.dragging = { id: chip.moduleId, lane: chip.lane, group: chip.slotGroup, index: chip.slotIndex };
                    root.target = root.targetAt(Qt.point(ghost.x + ghost.width / 2, ghost.y + ghost.height / 2));
                    return;
                }
                const t = root.target;
                if (!t) {
                    root.dragging = null;
                    root.target = null;
                    return;
                }
                root.drop(t.remove ? null : t);
            }
        }

        RowLayout {
            id: chipRow
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            MaterialSymbol {
                text: chip.info?.icon ?? "help"
                iconSize: Appearance.font.pixelSize.larger
                color: chip.colContent
            }
            StyledText {
                text: chip.info?.name ?? chip.moduleId
                font.pixelSize: Appearance.font.pixelSize.small
                color: chip.colContent
            }
            MaterialSymbol {
                visible: chip.placed
                text: "close"
                iconSize: Appearance.font.pixelSize.normal
                color: removeArea.containsMouse ? Appearance.colors.colError : chip.colContent
                MouseArea {
                    id: removeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.remove(chip.lane, chip.slotGroup, chip.slotIndex)
                }
            }
        }
    }

    component LaneFlow: Flow {
        spacing: 6
        move: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
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
                    implicitHeight: laneFlow.implicitHeight + 16
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    LaneFlow {
                        id: laneFlow
                        anchors {
                            fill: parent
                            margins: 8
                        }

                        Repeater {
                            model: Config.options.bar.layout[laneColumn.laneKey]
                            delegate: Rectangle {
                                id: groupBox
                                required property var modelData
                                required property int index
                                readonly property string editorRole: "group"
                                readonly property string laneKey: laneColumn.laneKey
                                readonly property int groupIndex: index
                                // Collapse instead of hiding: hiding an ancestor ends the chip's drag
                                readonly property bool empty: groupRow.implicitWidth < 1
                                implicitWidth: empty ? 0 : groupRow.implicitWidth + 8
                                implicitHeight: groupRow.implicitHeight + 8
                                opacity: empty ? 0 : 1
                                radius: Appearance.rounding.full
                                color: "transparent"
                                border.width: 1
                                border.color: Appearance.colors.colOutlineVariant

                                Row {
                                    id: groupRow
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Repeater {
                                        model: groupBox.modelData
                                        delegate: Row {
                                            id: slot
                                            required property string modelData
                                            required property int index
                                            Placeholder {
                                                open: root.targets(groupBox.laneKey, groupBox.index, slot.index)
                                            }
                                            Chip {
                                                moduleId: slot.modelData
                                                lane: groupBox.laneKey
                                                slotGroup: groupBox.index
                                                slotIndex: slot.index
                                            }
                                            Item { // Gap after the chip, gone while it is dragged away
                                                implicitWidth: slot.index < groupBox.modelData.length - 1 && !(root.dragging?.lane === groupBox.laneKey && root.dragging?.group === groupBox.index && root.dragging?.index === slot.index) ? 4 : 0
                                                implicitHeight: 1
                                            }
                                        }
                                    }
                                    Placeholder {
                                        gap: 0
                                        open: root.targets(groupBox.laneKey, groupBox.index, -1)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: newGroupRow.implicitWidth + 24
                            implicitHeight: 40
                            radius: Appearance.rounding.full
                            color: "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant

                            RowLayout {
                                id: newGroupRow
                                anchors.centerIn: parent
                                spacing: 4
                                Placeholder {
                                    open: root.targets(laneColumn.laneKey, -1, -1)
                                }
                                MaterialSymbol {
                                    text: "add"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: Translation.tr("New group")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
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
            implicitHeight: Math.max(availableFlow.implicitHeight + 16, 48)
            radius: Appearance.rounding.normal
            color: "transparent"
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            LaneFlow {
                id: availableFlow
                anchors {
                    fill: parent
                    margins: 8
                }

                Repeater {
                    model: root.unusedModules
                    delegate: Chip {
                        required property var modelData
                        moduleId: modelData.id
                    }
                }

                Placeholder {
                    gap: 0
                    open: availableZone.targeted
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.unusedModules.length === 0 && !availableZone.targeted
                text: Translation.tr("Drop a module here to remove it")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }
    }

    Rectangle {
        id: ghost
        property string moduleId: ""
        readonly property var info: BarModules.byId(moduleId)
        visible: root.dragging !== null
        z: 100
        implicitWidth: ghostRow.implicitWidth + 24
        implicitHeight: 32
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        onXChanged: if (root.dragging) root.target = root.targetAt(Qt.point(x + width / 2, y + height / 2))
        onYChanged: if (root.dragging) root.target = root.targetAt(Qt.point(x + width / 2, y + height / 2))

        RowLayout {
            id: ghostRow
            anchors.centerIn: parent
            spacing: 6
            MaterialSymbol {
                text: ghost.info?.icon ?? "help"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnPrimary
            }
            StyledText {
                text: ghost.info?.name ?? ghost.moduleId
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimary
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
