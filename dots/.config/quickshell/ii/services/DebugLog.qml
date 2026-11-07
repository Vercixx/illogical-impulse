pragma Singleton

import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Opt-in diagnostics for freezes and crashes: UI state breadcrumbs, event loop stalls, memory,
 * and a watchdog that saves the log to disk and aborts the shell when it stops answering IPC.
 */
Singleton {
    id: root

    readonly property bool enabled: Config.ready && Config.options.debug.logging
    readonly property string logDir: FileUtils.trimFileProtocol(`${Directories.state}/user/logs`)
    readonly property list<string> quietStates: ["superDown", "superReleaseMightTrigger", "screenLockContainsCharacters"]
    readonly property list<string> hyprlandEvents: ["openlayer", "closelayer", "fullscreen", "submap", "monitoradded", "monitorremoved", "configreloaded"]
    property bool statesHooked: false

    function load() {
        // dummy to force init
    }

    function note(message) {
        if (root.enabled)
            console.log(`[DebugLog] ${message}`);
    }

    // Connections can't be torn down per key, so handlers stay and check `enabled`
    function hookGlobalStates() {
        if (root.statesHooked)
            return;
        root.statesHooked = true;
        for (const key in GlobalStates) {
            const changed = GlobalStates[`${key}Changed`];
            if (typeof GlobalStates[key] !== "boolean" || !changed || root.quietStates.includes(key))
                continue;
            changed.connect(() => root.note(`${key}: ${GlobalStates[key]}`));
        }
    }

    LazyLoader {
        active: root.enabled
        component: Scope {
            Component.onCompleted: {
                root.hookGlobalStates();
                root.note(`Enabled, saving logs to ${root.logDir}`);
            }

            Process {
                running: true
                command: ["bash", FileUtils.trimFileProtocol(`${Directories.scriptPath}/debug/watchdog.sh`), Quickshell.processId, root.logDir]
            }

            Timer {
                property real last: Date.now()
                interval: 500
                running: true
                repeat: true
                onTriggered: {
                    const now = Date.now();
                    const gap = now - last - interval;
                    last = now;
                    if (gap > 1000)
                        console.warn(`[DebugLog] Event loop blocked for ${gap} ms (or system was suspended)`);
                }
            }

            FileView {
                id: procStatus
                path: "/proc/self/status"
            }

            Timer {
                interval: 60000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    procStatus.reload();
                    const text = procStatus.text();
                    const mb = key => Math.round(Number(text.match(new RegExp(`${key}:\\s*(\\d+)`))?.[1] ?? 0) / 1024);
                    root.note(`Memory: RSS ${mb("VmRSS")} MB, peak ${mb("VmHWM")} MB`);
                }
            }

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    if (root.hyprlandEvents.includes(event.name))
                        root.note(`Hyprland ${event.name} ${event.data}`);
                }
            }
        }
    }
}
