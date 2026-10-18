import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    Loader {
        id: cheatsheetLoader
        active: false

        sourceComponent: FloatingWindow {
            id: cheatsheetWindow
            title: "illogical-impulse Keybinds"
            implicitWidth: 720
            implicitHeight: 680
            minimumSize: Qt.size(480, 360)
            color: Appearance.m3colors.m3background

            onClosed: cheatsheetLoader.active = false

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 12

                Item {
                    visible: Config.options?.windows.showTitlebar
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    implicitHeight: Math.max(titleRow.implicitHeight, windowControlsRow.implicitHeight)
                    RowLayout {
                        id: titleRow
                        anchors {
                            left: Config.options.windows.centerTitle ? undefined : parent.left
                            horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12
                        }
                        spacing: 6
                        MaterialSymbol {
                            text: "keyboard"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            color: Appearance.colors.colOnLayer0
                            text: Translation.tr("Keybinds")
                            font {
                                family: Appearance.font.family.title
                                pixelSize: Appearance.font.pixelSize.larger
                                weight: Font.Bold
                            }
                        }
                    }
                    RowLayout { // Window controls row
                        id: windowControlsRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            implicitWidth: 35
                            implicitHeight: 35
                            onClicked: cheatsheetLoader.active = false
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: 20
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: Appearance.rounding.full
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 8
                        }
                        spacing: 4

                        MaterialSymbol {
                            text: "search"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colSubtext
                        }
                        ToolbarTextField {
                            id: searchField
                            Layout.fillWidth: true
                            focus: true
                            colBackground: "transparent"
                            placeholderText: Translation.tr("Search keybinds")
                            Keys.onEscapePressed: cheatsheetLoader.active = false
                        }
                    }
                }

                CheatsheetKeybinds {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    query: searchField.text
                }
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            cheatsheetLoader.active = !cheatsheetLoader.active;
        }

        function close(): void {
            cheatsheetLoader.active = false;
        }

        function open(): void {
            cheatsheetLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"

        onPressed: {
            cheatsheetLoader.active = !cheatsheetLoader.active;
        }
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"

        onPressed: {
            cheatsheetLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"

        onPressed: {
            cheatsheetLoader.active = false;
        }
    }
}
