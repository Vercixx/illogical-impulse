pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    property var monitors: []
    property var drafts: ({})
    property var loadedDrafts: ({})
    property string selectedName: ""
    readonly property var selected: monitors.find(m => m.name === selectedName) ?? null
    readonly property var selectedDraft: drafts[selectedName] ?? null
    readonly property var changedNames: Object.keys(drafts).filter(name => page.serialize(drafts[name]) !== loadedDrafts[name])
    readonly property int enabledCount: Object.values(drafts).filter(d => !d.disabled).length

    property var revertEntries: null
    property var revertResetKeys: null
    property int revertSeconds: 0

    function modeOf(m) {
        if (m.width > 0)
            return `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}`;
        return (m.availableModes[0] ?? "1920x1080@60.00Hz").replace("Hz", "");
    }

    function draftFor(m) {
        const draft = { mode: modeOf(m), x: m.x, y: m.y, scale: m.scale, transform: m.transform, disabled: m.disabled };
        const saved = HyprlandConfig.settingsValues[`monitor:${m.name}`];
        if (typeof saved !== "string")
            return draft;
        for (const field of saved.split(",")) {
            const [name, value] = field.split("=");
            if (name === "mode") draft.mode = value;
            else if (name === "position" && value.includes("x")) [draft.x, draft.y] = value.split("x").map(Number);
            else if (name === "scale") draft.scale = Number(value);
            else if (name === "transform") draft.transform = Number(value);
            else if (name === "disabled") draft.disabled = value === "1";
        }
        return draft;
    }

    function serialize(d) {
        return `mode=${d.mode},position=${d.x}x${d.y},scale=${d.scale},transform=${d.transform},disabled=${d.disabled}`;
    }

    function rebuild() {
        const drafts = {};
        const loadedDrafts = {};
        for (const m of monitors) {
            drafts[m.name] = draftFor(m);
            loadedDrafts[m.name] = serialize(drafts[m.name]);
        }
        page.drafts = drafts;
        page.loadedDrafts = loadedDrafts;
        if (!monitors.some(m => m.name === selectedName))
            selectedName = (monitors.find(m => m.focused) ?? monitors[0])?.name ?? "";
    }

    function setDraft(field, value) {
        if (!selectedDraft || selectedDraft[field] === value)
            return;
        page.drafts = Object.assign({}, drafts, { [selectedName]: Object.assign({}, selectedDraft, { [field]: value }) });
    }

    function logicalSize(d) {
        const [w, h] = d.mode.split("@")[0].split("x").map(Number);
        const rotated = d.transform % 2 === 1;
        return { width: (rotated ? h : w) / d.scale, height: (rotated ? w : h) / d.scale };
    }

    function validScales(mode) {
        const [w, h] = mode.split("@")[0].split("x").map(Number);
        const fits = s => Math.abs(w / s - Math.round(w / s)) < 0.01 && Math.abs(h / s - Math.round(h / s)) < 0.01;
        return [1, 1.2, 1.25, 1.5, 1.6, 1.75, 2, 2.4, 2.5, 3].filter(fits);
    }

    function apply() {
        const entries = {};
        const revertEntries = {};
        const revertResetKeys = [];
        for (const name of changedNames) {
            const key = `monitor:${name}`;
            entries[key] = serialize(drafts[name]);
            if (HyprlandConfig.settingsValues[key] !== undefined)
                revertEntries[key] = loadedDrafts[name];
            else
                revertResetKeys.push(key);
        }
        page.revertEntries = revertEntries;
        page.revertResetKeys = revertResetKeys;
        page.revertSeconds = 15;
        HyprlandConfig.editUser(entries, []);
    }

    function revert() {
        HyprlandConfig.editUser(revertEntries, revertResetKeys);
        page.revertSeconds = 0;
    }

    Process {
        id: monitorsProc
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.monitors = JSON.parse(text);
                page.rebuild();
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved"))
                monitorsProc.running = true;
        }
    }
    Connections {
        target: HyprlandConfig
        function onReloaded() {
            monitorsProc.running = true;
        }
        function onSettingsValuesChanged() {
            page.rebuild();
        }
    }

    Timer {
        running: page.revertSeconds > 0
        interval: 1000
        repeat: true
        onTriggered: {
            page.revertSeconds -= 1;
            if (page.revertSeconds === 0)
                page.revert();
        }
    }

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Arrangement")

        Rectangle {
            id: preview
            Layout.fillWidth: true
            implicitHeight: 240
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2

            readonly property var shown: page.monitors.filter(m => page.drafts[m.name] && !page.drafts[m.name].disabled)
            readonly property var bounds: {
                let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                for (const m of shown) {
                    const d = page.drafts[m.name];
                    const size = page.logicalSize(d);
                    minX = Math.min(minX, d.x);
                    minY = Math.min(minY, d.y);
                    maxX = Math.max(maxX, d.x + size.width);
                    maxY = Math.max(maxY, d.y + size.height);
                }
                return shown.length ? { x: minX, y: minY, width: maxX - minX, height: maxY - minY } : { x: 0, y: 0, width: 1, height: 1 };
            }
            readonly property real factor: Math.min((width - 40) / bounds.width, (height - 40) / bounds.height)
            readonly property real offsetX: (width - bounds.width * factor) / 2
            readonly property real offsetY: (height - bounds.height * factor) / 2

            Repeater {
                model: page.monitors
                delegate: Rectangle {
                    id: monitorRect
                    required property var modelData
                    readonly property var draft: page.drafts[modelData.name] ?? { mode: "1x1@0", x: 0, y: 0, scale: 1, transform: 0, disabled: true }
                    readonly property var size: page.logicalSize(draft)
                    visible: !draft.disabled
                    readonly property bool isSelected: modelData.name === page.selectedName

                    function placeX() { return preview.offsetX + (draft.x - preview.bounds.x) * preview.factor; }
                    function placeY() { return preview.offsetY + (draft.y - preview.bounds.y) * preview.factor; }

                    x: placeX()
                    y: placeY()
                    width: size.width * preview.factor
                    height: size.height * preview.factor
                    radius: Appearance.rounding.small
                    color: isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                    border.width: 1
                    border.color: Appearance.colors.colOutline

                    StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: `${monitorRect.modelData.name}\n${monitorRect.draft.mode.split("@")[0]}`
                        color: monitorRect.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: preview.shown.length > 1 ? monitorRect : null
                        onPressed: page.selectedName = monitorRect.modelData.name
                        onReleased: {
                            if (!drag.active)
                                return;
                            const x = Math.round((monitorRect.x - preview.offsetX) / preview.factor + preview.bounds.x);
                            const y = Math.round((monitorRect.y - preview.offsetY) / preview.factor + preview.bounds.y);
                            const snapped = monitorRect.snap(x, y);
                            page.setDraft("x", snapped.x);
                            page.setDraft("y", snapped.y);
                            monitorRect.x = Qt.binding(monitorRect.placeX);
                            monitorRect.y = Qt.binding(monitorRect.placeY);
                        }
                    }

                    function snap(x, y) {
                        const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);
                        const align = (v, targets, threshold) => targets.find(t => Math.abs(t - v) < threshold) ?? v;
                        let best = { x: x, y: y, dist: Infinity };
                        const consider = (cx, cy) => {
                            const dist = Math.hypot(cx - x, cy - y);
                            if (dist < best.dist)
                                best = { x: cx, y: cy, dist: dist };
                        };
                        for (const other of preview.shown) {
                            if (other.name === modelData.name)
                                continue;
                            const o = page.drafts[other.name];
                            const os = page.logicalSize(o);
                            const sideY = clamp(align(y, [o.y, o.y + os.height - size.height], os.height * 0.1), o.y - size.height, o.y + os.height);
                            consider(o.x - size.width, sideY);
                            consider(o.x + os.width, sideY);
                            const stackX = clamp(align(x, [o.x, o.x + os.width - size.width], os.width * 0.1), o.x - size.width, o.x + os.width);
                            consider(stackX, o.y - size.height);
                            consider(stackX, o.y + os.height);
                        }
                        return { x: Math.round(best.x), y: Math.round(best.y) };
                    }
                }
            }
        }

        StyledText {
            visible: page.monitors.length > 1
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            text: Translation.tr("Click a monitor to select it. Drag it to change its position.")
        }
    }

    ContentSection {
        visible: page.selectedDraft !== null
        icon: "display_settings"
        title: [page.selected?.name, page.selected?.description].filter(Boolean).join(": ")

        ConfigSwitch {
            buttonIcon: "power_settings_new"
            text: Translation.tr("Enabled")
            enabled: page.selectedDraft?.disabled || page.enabledCount > 1
            Binding on checked {
                value: !(page.selectedDraft?.disabled ?? false)
            }
            onCheckedChanged: page.setDraft("disabled", !checked)
        }

        ContentSubsection {
            title: Translation.tr("Resolution and refresh rate")
            StyledComboBox {
                buttonIcon: "aspect_ratio"
                model: page.selected?.availableModes.map(mode => mode.replace("Hz", "")) ?? []
                currentIndex: model.indexOf(page.selectedDraft?.mode ?? "")
                displayText: (page.selectedDraft?.mode ?? "").replace("@", " @ ") + " Hz"
                onActivated: index => page.setDraft("mode", model[index])
            }
        }

        ContentSubsection {
            title: Translation.tr("Scale")
            ConfigSelectionArray {
                currentValue: page.selectedDraft?.scale
                onSelected: newValue => page.setDraft("scale", newValue)
                options: {
                    const scales = page.validScales(page.selectedDraft?.mode ?? "1x1@0");
                    const current = page.selectedDraft?.scale;
                    if (current !== undefined && !scales.includes(current))
                        scales.push(current);
                    return scales.sort((a, b) => a - b).map(s => ({ "value": s, "displayName": `${Math.round(s * 100)}%` }));
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Rotation")
            ConfigSelectionArray {
                currentValue: page.selectedDraft?.transform
                onSelected: newValue => page.setDraft("transform", newValue)
                options: [
                    { "value": 0, "displayName": Translation.tr("None") },
                    { "value": 1, "displayName": "90°" },
                    { "value": 2, "displayName": "180°" },
                    { "value": 3, "displayName": "270°" }
                ]
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "arrow_range"
                text: Translation.tr("X position")
                from: -32768
                to: 32768
                Binding on value {
                    value: page.selectedDraft?.x ?? 0
                }
                onValueModified: page.setDraft("x", value)
            }
            ConfigSpinBox {
                icon: "height"
                text: Translation.tr("Y position")
                from: -32768
                to: 32768
                Binding on value {
                    value: page.selectedDraft?.y ?? 0
                }
                onValueModified: page.setDraft("y", value)
            }
        }
    }

    ContentSection {
        icon: "check"
        title: Translation.tr("Apply")

        StyledText {
            visible: page.revertSeconds > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colOnLayer1
            text: Translation.tr("Keep these display settings? Reverting in %1 s").arg(page.revertSeconds)
        }

        ConfigRow {
            uniform: true
            RippleButtonWithIcon {
                visible: page.revertSeconds === 0
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "restart_alt"
                mainText: Translation.tr("Reset monitor")
                enabled: HyprlandConfig.settingsValues[`monitor:${page.selectedName}`] !== undefined
                onClicked: HyprlandConfig.resetUserMany([`monitor:${page.selectedName}`])
            }
            RippleButtonWithIcon {
                visible: page.revertSeconds === 0
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "check"
                mainText: Translation.tr("Apply")
                enabled: page.changedNames.length > 0
                onClicked: page.apply()
            }
            RippleButtonWithIcon {
                visible: page.revertSeconds > 0
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "undo"
                mainText: Translation.tr("Revert")
                onClicked: page.revert()
            }
            RippleButtonWithIcon {
                visible: page.revertSeconds > 0
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "check"
                mainText: Translation.tr("Keep")
                onClicked: page.revertSeconds = 0
            }
        }
    }
}
