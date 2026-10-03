pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.modules.common
import qs.modules.common.functions

/**
 * Configs Hyprland
 */
Singleton {
    id: root

    signal reloaded()

    readonly property string configuratorScriptPath: Quickshell.shellPath("scripts/hyprland/hyprconfigurator.py")
    readonly property string conflictScriptPath: Quickshell.shellPath("scripts/hyprland/find_conflicts.lua")
    readonly property string shellOverridesPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/shellOverrides/main.lua`)
    readonly property string customDir: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom`)
    readonly property string settingsPath: `${root.customDir}/shell.lua`

    property var settingsValues: ({})
    property list<var> conflicts: []
    readonly property list<var> pendingConflicts: conflicts.filter(c => !Config.options.hyprland.keptSettingsConflicts.includes(`${c.key}=${c.fileValue}`))

    // if shell.lua was just created, there's a huge chance hyprland won't load it
    // unless u do a force reload. this does exactly that
    function run(file: string, args: string) {
        Quickshell.execDetached(["bash", "-c", `test -f '${file}'; existed=$?; ${root.configuratorScriptPath} --file '${file}' ${args}; [ $existed -eq 0 ] || hyprctl reload`])
    }

    function setArgs(entries: var): string {
        let args = ""
        for (let key in entries) {
            args += `--set "${key}" "${entries[key]}" `
        }
        return args
    }

    function resetArgs(keys: list<string>): string {
        let args = ""
        for (let i = 0; i < keys.length; i++) {
            args += `--reset "${keys[i]}" `
        }
        return args
    }

    function set(key: string, value: var) {
        root.run(root.shellOverridesPath, root.setArgs({ [key]: value }))
    }

    function setMany(entries: var) {
        root.run(root.shellOverridesPath, root.setArgs(entries))
    }

    function reset(key: string) {
        root.run(root.shellOverridesPath, root.resetArgs([key]))
    }

    function resetMany(keys: list<string>) {
        root.run(root.shellOverridesPath, root.resetArgs(keys))
    }

    function setUser(key: string, value: var) {
        root.run(root.settingsPath, root.setArgs({ [key]: value }))
    }

    function resetUserMany(keys: list<string>) {
        root.run(root.settingsPath, root.resetArgs(keys))
    }

    function editUser(entries: var, resetKeys: list<string>) {
        root.run(root.settingsPath, root.setArgs(entries) + root.resetArgs(resetKeys))
    }

    function keepSettingsValue(conflict: var) {
        Config.options.hyprland.keptSettingsConflicts = [...Config.options.hyprland.keptSettingsConflicts, `${conflict.key}=${conflict.fileValue}`]
    }

    function keepCustomValue(conflict: var) {
        root.resetUserMany([conflict.key])
        root.conflicts = root.conflicts.filter(c => c !== conflict)
    }

    function readSettingsFile() {
        conflictProc.running = false
        conflictProc.running = true
        dumpProc.running = false
        dumpProc.running = true
    }

    Process {
        id: dumpProc
        command: ["lua", root.conflictScriptPath, "--dump", root.settingsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = {}
                for (const line of text.split("\n").filter(line => line.length > 0)) {
                    const [key, value] = line.split("\t")
                    values[key] = value === "" || isNaN(Number(value)) ? value : Number(value)
                }
                root.settingsValues = values
            }
        }
    }

    Process {
        id: conflictProc
        command: ["bash", "-c", `lua '${root.conflictScriptPath}' '${root.settingsPath}' '${root.customDir}'/*.lua`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.conflicts = text.split("\n").filter(line => line.length > 0).map(line => {
                    const [key, file, fileValue, shellValue] = line.split("\t")
                    return { key, file, fileValue, shellValue }
                })
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reloaded()
            }
        }
    }
}
