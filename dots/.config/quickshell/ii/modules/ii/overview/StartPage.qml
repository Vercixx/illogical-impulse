pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

// Start menu body under the search bar when BarOptions.taskbar is on
Item {
    id: root

    readonly property var pinned: Config.options.launcher.pinnedApps.map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id)).filter(e => e)
    readonly property var allApps: [...DesktopEntries.applications.values.filter(e => !e.noDisplay)].sort((a, b) => a.name.localeCompare(b.name))

    implicitWidth: 520 + Appearance.sizes.elevationMargin * 2
    implicitHeight: 560 + Appearance.sizes.elevationMargin * 2

    function launch(entry) {
        GlobalStates.overviewOpen = false;
        entry.execute();
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        radius: Appearance.rounding.windowRounding
        color: Appearance.colors.colBackgroundSurfaceContainer

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            SectionLabel {
                visible: root.pinned.length > 0
                text: Translation.tr("Pinned")
            }
            GridLayout {
                visible: root.pinned.length > 0
                Layout.fillWidth: true
                columns: 6
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: root.pinned
                    delegate: AppButton {
                        required property var modelData
                        entry: modelData
                        tile: true
                        Layout.fillWidth: true
                    }
                }
            }

            SectionLabel {
                text: Translation.tr("All apps")
            }
            StyledListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                popin: false
                animateAppearance: false
                model: root.allApps
                delegate: AppButton {
                    required property var modelData
                    entry: modelData
                    width: ListView.view.width
                }
            }

            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol {
                    text: "account_circle"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: SystemInfo.username
                    color: Appearance.colors.colOnLayer1
                }
                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    onClicked: {
                        GlobalStates.overviewOpen = false;
                        GlobalStates.sessionOpen = true;
                    }
                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        text: "power_settings_new"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledToolTip {
                        text: Translation.tr("Session")
                    }
                }
            }
        }
    }

    component SectionLabel: StyledText {
        Layout.leftMargin: 4
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
    }

    // Right click pins or unpins
    component AppButton: RippleButton {
        id: button
        required property var entry
        property bool tile: false
        implicitHeight: tile ? 76 : 40
        buttonRadius: Appearance.rounding.small
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        onClicked: root.launch(button.entry)
        altAction: () => LauncherApps.togglePin(button.entry.id)

        contentItem: GridLayout {
            flow: button.tile ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columnSpacing: 10
            rowSpacing: 4
            AppIcon {
                Layout.alignment: button.tile ? Qt.AlignHCenter : Qt.AlignVCenter
                Layout.leftMargin: button.tile ? 0 : 8
                implicitSize: button.tile ? 32 : 24
                source: button.entry.icon || AppSearch.guessIcon(button.entry.id)
            }
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: button.tile ? 76 : -1
                horizontalAlignment: button.tile ? Text.AlignHCenter : Text.AlignLeft
                text: button.entry.name
                elide: Text.ElideRight
                font.pixelSize: button.tile ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
