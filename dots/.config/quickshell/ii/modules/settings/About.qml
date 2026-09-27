import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property var info: ({ gpu: [], disk: [] })

    readonly property var softwareInfo: [
        [Translation.tr("Kernel"), info.kernel],
        [Translation.tr("Hyprland"), info.hyprland],
        [Translation.tr("Quickshell"), info.quickshell],
        [Translation.tr("Desktop"), SystemInfo.desktopEnvironment],
        [Translation.tr("Graphics platform"), SystemInfo.windowingSystem],
    ].filter(([_, value]) => value)

    readonly property var hardwareInfo: [
        ["memory", Translation.tr("Processor"), info.cpu ? `${info.cpu}\n${Translation.tr("%1 threads").arg(info.threads)}` : ""],
        ["memory_alt", Translation.tr("Memory"), ResourceUsage.maxAvailableMemoryString],
        ["developer_board", Translation.tr("Graphics"), info.gpu.join("\n")],
        ["hard_drive", Translation.tr("Storage"), info.disk.join("\n")],
        ["monitor", Translation.tr("Displays"), HyprlandData.monitors.map(m => `${m.model || m.name}: ${m.width}×${m.height} @ ${Math.round(m.refreshRate)} Hz`).join("\n")],
        ["computer", Translation.tr("Device"), info.product?.startsWith(info.vendor) ? info.product : [info.vendor, info.product].filter(Boolean).join(" ")],
    ].filter(([_, __, value]) => value)

    function gpuName(vendor, device) {
        const brand = vendor.match(/\[([^\]\/]+)/)?.[1] ?? vendor.split(" ")[0];
        return `${brand} ${device.match(/\[(.+)\]/)?.[1] ?? device}`;
    }

    function copyDetails() {
        Quickshell.clipboardText = [
            SystemInfo.distroName,
            ...softwareInfo.map(([label, value]) => `${label}: ${value}`),
            ...hardwareInfo.map(([_, label, value]) => `${label}: ${value.replace(/\n/g, "; ")}`),
        ].join("\n");
    }

    Process {
        running: true
        command: ["bash", "-c", `
            printf 'kernel\\t%s\\n' "$(uname -r)"
            printf 'hyprland\\t%s\\n' "$(hyprctl version -j 2>/dev/null | grep -m1 '"version"' | cut -d'"' -f4)"
            printf 'quickshell\\t%s\\n' "$(qs --version 2>/dev/null | cut -d' ' -f2)"
            printf 'cpu\\t%s\\n' "$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | xargs)"
            printf 'threads\\t%s\\n' "$(nproc)"
            printf 'vendor\\t%s\\n' "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)"
            printf 'product\\t%s\\n' "$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
            lspci -mm 2>/dev/null | awk -F'"' '/VGA|3D|Display/ { print "gpu\\t" $4 "\\t" $6 }'
            lsblk -dno NAME,SIZE,MODEL -e 1,7,11 | awk '$1 !~ /^zram/ { $1 = ""; print "disk\\t" substr($0, 2) }'
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = { gpu: [], disk: [] };
                for (const line of text.split("\n")) {
                    const [key, value = "", extra = ""] = line.split("\t");
                    if (!value.trim()) continue;
                    if (key === "gpu") result.gpu.push(root.gpuName(value, extra));
                    else if (key === "disk") result.disk.push(value.trim());
                    else result[key] = value.trim();
                }
                root.info = result;
            }
        }
    }

    component HardwareCard: Rectangle {
        id: card
        required property var modelData
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        implicitHeight: cardContent.implicitHeight + 28
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2

        RowLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 12
            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: card.modelData[0]
                iconSize: Appearance.font.pixelSize.huge
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2
                StyledText {
                    text: card.modelData[1]
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.fillWidth: true
                    text: card.modelData[2]
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    ContentSection {
        icon: "box"
        title: Translation.tr("Distro")
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath(SystemInfo.logo)
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: SystemInfo.homeUrl
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.documentationUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "support"
                mainText: Translation.tr("Help & Support")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.supportUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Report a Bug")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.bugReportUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "policy"
                materialIconFill: false
                mainText: Translation.tr("Privacy Policy")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
                }
            }
            
        }

    }

    ContentSection {
        icon: "terminal"
        title: Translation.tr("Software")

        Repeater {
            model: root.softwareInfo
            delegate: RowLayout {
                id: softwareRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 12
                StyledText {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignRight
                    text: softwareRow.modelData[0]
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: softwareRow.modelData[1]
                    elide: Text.ElideRight
                }
            }
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Hardware")

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6
            Repeater {
                model: root.hardwareInfo
                delegate: HardwareCard {}
            }
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignRight
            materialIcon: "content_copy"
            materialIconFill: false
            mainText: Translation.tr("Copy details")
            onClicked: root.copyDetails()
        }
    }

    ContentSection {
        icon: "folder_managed"
        title: Translation.tr("Dotfiles")

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath("illogical-impulse")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: Translation.tr("illogical-impulse")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/Vercixx/illogical-impulse"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
                StyledText {
                	text: Translation.tr("forked from https://github.com/end-4/dots-hyprland")
                	font.pixelSize: Appearance.font.pixelSize.small
                	textFormat: Text.MarkdownText
                	onLinkActivated: (link) => {
                		Qt.openUrlExternally(link)
                	}
                	HoverHandler {
                		enabled: parent.hoveredLink
                		cursorShape: Qt.PointingHandCursor
                	}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/Vercixx/illogical-impulse/issues")
                }
            }
            /* RippleButtonWithIcon {
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/Vercixx/illogical-impulse/discussions")
                }
            } */
            RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: Translation.tr("Donate")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/sponsors/end-4")
                }
            }

            
        }
    }
}
