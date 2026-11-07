pragma Singleton
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Singleton {
    id: root

    property string windowsBootEntryId: ""
    readonly property bool windowsBootEntryAvailable: windowsBootEntryId !== ""

    function closeAllWindows() {
        HyprlandData.windowList.map(w => w.pid).forEach(pid => {
            Quickshell.execDetached(["kill", pid]);
        });
    }

    function changePassword() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.changePassword}`]);
    }

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        closeAllWindows();
        Quickshell.execDetached(["pkill", "-i", "Hyprland"]);
    }

    function launchTaskManager() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]);
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]);
    }

    function poweroff() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }

    function reboot() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }

    function rebootToFirmware() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]);
    }

    function refreshWindowsBootEntry() {
        windowsBootEntryProc.running = false;
        windowsBootEntryProc.running = true;
    }

    function rebootToWindows() {
        if (!windowsBootEntryAvailable) return;
        setWindowsBootEntryProc.running = false;
        setWindowsBootEntryProc.running = true;
    }

    Process {
        id: windowsBootEntryProc
        running: true // also check at shell reload
        command: ["bash", "-c", "command -v efibootmgr >/dev/null 2>&1 && efibootmgr 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const enabledEntry = text.match(/^Boot([0-9A-Fa-f]{4})\*\s+Windows Boot Manager/mi);
                const disabledEntry = text.match(/^Boot([0-9A-Fa-f]{4})\s+Windows Boot Manager/mi);
                root.windowsBootEntryId = enabledEntry ? enabledEntry[1] : (disabledEntry ? disabledEntry[1] : "");
            }
        }
    }

    Process {
        id: setWindowsBootEntryProc
        command: ["bash", "-c", `pkexec efibootmgr --bootnext ${root.windowsBootEntryId}`]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) return;
            root.reboot();
        }
    }
}
