import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects

BarDrawer {
    id: root

    controls: Component {
        ColumnLayout {
            id: details
            spacing: 8
            implicitWidth: 340

            property string loadAverage: "--"
            property string processes: "--"
            property string cpuModel: ""
            property string disk: "--"
            property list<var> topProcesses: []

            function refresh() {
                loadavgFile.reload();
                const fields = loadavgFile.text().trim().split(/\s+/);
                if (fields.length >= 4) {
                    details.loadAverage = fields.slice(0, 3).join("  ");
                    details.processes = Translation.tr("%1 running of %2").arg(fields[3].split("/")[0]).arg(fields[3].split("/")[1]);
                }
                if (!statusProc.running)
                    statusProc.running = true;
            }

            Timer {
                interval: Config.options?.resources?.updateInterval ?? 3000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: details.refresh()
            }
            FileView {
                id: loadavgFile
                path: "/proc/loadavg"
            }
            FileView {
                path: "/proc/cpuinfo"
                onLoaded: details.cpuModel = (text().match(/model name\s*:\s*(.+)/)?.[1] ?? "").trim()
            }
            Process {
                id: statusProc
                environment: ({
                    LANG: "C",
                    LC_ALL: "C"
                })
                // The second top sample measures the last 0.3 s; the first one averages since each process started
                command: ["bash", "-c", "df -B1 --output=used,size / | tail -1; top -b -n 2 -d 0.3 -o %CPU -w 512 | awk '/^ *PID/{n++; next} n==2' | grep -v ' top$' | head -5"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = text.trim().split("\n");
                        const disk = (lines.shift() ?? "").trim().split(/\s+/).map(Number);
                        if (disk.length === 2 && disk[1] > 0)
                            details.disk = `${(disk[0] / 1e9).toFixed(0)} / ${(disk[1] / 1e9).toFixed(0)} GB`;
                        details.topProcesses = lines.map(line => line.trim().split(/\s+/)).filter(f => f.length >= 12).map(f => ({
                            name: f.slice(11).join(" "),
                            cpu: Number(f[8])
                        }));
                    }
                }
            }

            component HistoryGraph: Rectangle {
                id: graphTile
                required property string label
                required property real value
                required property list<real> history
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Appearance.rounding.verysmall
                color: Appearance.colors.colSecondaryContainer
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: graphTile.width
                        height: graphTile.height
                        radius: graphTile.radius
                    }
                }
                Graph {
                    anchors.fill: parent
                    values: graphTile.history
                    points: ResourceUsage.historyLength
                    alignment: Graph.Alignment.Right
                }
                StyledText {
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: 6
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSecondaryContainer
                    text: graphTile.label
                }
                StyledText {
                    anchors {
                        right: parent.right
                        top: parent.top
                        margins: 6
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSecondaryContainer
                    text: `${Math.round(graphTile.value * 100)}%`
                }
            }

            HistoryGraph {
                label: "CPU"
                value: ResourceUsage.cpuUsage
                history: ResourceUsage.cpuUsageHistory
            }
            HistoryGraph {
                label: "RAM"
                value: ResourceUsage.memoryUsedPercentage
                history: ResourceUsage.memoryUsageHistory
            }
            HistoryGraph {
                visible: ResourceUsage.swapTotal > 0
                label: "Swap"
                value: ResourceUsage.swapUsedPercentage
                history: ResourceUsage.swapUsageHistory
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                StyledPopupValueRow {
                    Layout.fillWidth: true
                    visible: details.cpuModel !== ""
                    icon: "developer_board"
                    label: Translation.tr("Model:")
                    value: details.cpuModel
                }
                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "speed"
                    label: Translation.tr("Load average:")
                    value: details.loadAverage
                }
                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "account_tree"
                    label: Translation.tr("Processes:")
                    value: details.processes
                }
                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "timelapse"
                    label: Translation.tr("System uptime:")
                    value: DateTime.uptime
                }
                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "hard_drive"
                    label: Translation.tr("Disk:")
                    value: details.disk
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: details.topProcesses.length > 0
                spacing: 4
                StyledPopupHeaderRow {
                    icon: "bar_chart"
                    label: Translation.tr("Top processes")
                }
                Repeater {
                    model: details.topProcesses
                    delegate: StyledPopupValueRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: "memory"
                        label: modelData.name
                        value: `${modelData.cpu.toFixed(1)}%`
                    }
                }
            }
        }
    }

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            }
        }

        Column {
            visible: ResourceUsage.swapTotal > 0
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                }
            }
        }
    }
}
