pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Manages data related to Drift layout
 */
Singleton {
    id: root

    readonly property string layoutName: "lua:drift"
    readonly property bool active: HyprlandData.activeWorkspace?.tiledLayout === layoutName
    property var cameras: ({})
    property var bookmarks: ({})

    function activeOn(workspaceId: int): bool {
        return HyprlandData.workspaceById[workspaceId]?.tiledLayout === root.layoutName;
    }

    function cameraFor(workspaceId: int): point {
        return root.cameras[workspaceId] ?? Qt.point(0, 0);
    }

    function bookmarksFor(workspaceId: int): var {
        return root.bookmarks[workspaceId] ?? [];
    }

    function goToBookmark(slot: int) {
        Hyprland.dispatch(`hl.dsp.layout("bookmark go ${slot}")`);
    }

    // Activating the already focused window sends no focus event for drift.lua
    function reveal(toplevel: var) {
        const address = toplevel?.HyprlandToplevel?.address;
        if (!root.active || !address)
            return;
        Hyprland.dispatch(`hl.dsp.layout("reveal 0x${address}")`);
    }

    function lookAt(x: real, y: real) {
        Hyprland.dispatch(`hl.dsp.layout("look ${Math.round(x)} ${Math.round(y)}")`);
    }

    onActiveChanged: {
        if (!root.active)
            return;
        Hyprland.dispatch(`hl.dsp.layout("sync")`);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "custom")
                return;
            if (event.data.startsWith("drift>>cam ")) {
                const [id, x, y] = event.data.slice(11).split(" ").map(Number);
                const next = Object.assign({}, root.cameras);
                next[id] = Qt.point(x, y);
                root.cameras = next;
            } else if (event.data.startsWith("drift>>marks ")) {
                const [id, ...items] = event.data.slice(13).split(" ");
                const next = Object.assign({}, root.bookmarks);
                next[Number(id)] = items.filter(item => item.length > 0).map(item => {
                    const [slot, x, y] = item.split(":").map(Number);
                    return { slot: slot, x: x, y: y };
                });
                root.bookmarks = next;
            }
        }
    }
}
