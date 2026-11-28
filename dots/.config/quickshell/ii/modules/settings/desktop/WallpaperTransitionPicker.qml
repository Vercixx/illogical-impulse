pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

GridLayout {
    id: root
    required property bool inView
    Layout.fillWidth: true
    columns: Math.max(1, Math.min(3, Math.floor((width + columnSpacing) / 155)))
    uniformCellWidths: true
    rowSpacing: 8
    columnSpacing: 8

    readonly property var labels: ({
        random: Translation.tr("Random"),
        fade: Translation.tr("Crossfade"),
        wipe: Translation.tr("Wipe"),
        slide: Translation.tr("Slide"),
        zoom: Translation.tr("Zoom"),
        none: Translation.tr("None")
    })
    property int previewStep: 0
    SequentialAnimation {
        loops: Animation.Infinite
        running: root.inView && root.visible && root.Window.window?.visible === true && root.Window.window.visibility !== Window.Minimized
        PauseAnimation { duration: 1400 }
        ScriptAction { script: root.previewStep = (root.previewStep + 1) % Wallpapers.slideDirections.length }
        PauseAnimation { duration: Wallpapers.transitionDuration }
    }

    Repeater {
        model: ["random", ...Wallpapers.transitionEffects, "none"]

        RippleButton {
            id: card
            required property string modelData
            readonly property bool hasPreview: modelData !== "random" && modelData !== "none"
            readonly property color labelColor: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            padding: 8
            buttonRadius: 12
            colBackground: Appearance.colors.colLayer2
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            text: root.labels[modelData]
            toggled: Config.options.background.transition === modelData
            onClicked: Config.options.background.transition = modelData
            Accessible.role: Accessible.RadioButton
            Accessible.name: text
            Accessible.checkable: true
            Accessible.checked: toggled

            contentItem: ColumnLayout {
                spacing: 5
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    sourceComponent: card.hasPreview ? preview : icon

                    Component {
                        id: icon
                        MaterialSymbol {
                            text: card.modelData === "random" ? "shuffle" : "block"
                            iconSize: 40
                            color: card.labelColor
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    Component {
                        id: preview
                        WallpaperTransition {
                            effect: card.modelData
                            direction: Wallpapers.directionFor(effect, root.previewStep)
                            duration: Wallpapers.transitionDuration
                            path: Directories.assetsPath + "/images/" + (root.previewStep % 2 ? "default_wallpaper_drift.png" : "default_wallpaper.png")
                            imageComponent: Image {
                                id: sample
                                anchors.fill: parent
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                                readonly property bool warm: source.toString().endsWith("_drift.png")
                                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                                layer.effect: LevelAdjust {
                                    minimumInput: "#00161316"
                                    maximumInput: "#4d4150"
                                    minimumOutput: sample.warm ? "#00913e46" : "#001c4466"
                                    maximumOutput: sample.warm ? "#ffd18a" : "#8fdbcb"
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !sample.layer.enabled
                                    color: sample.warm ? "#88ef9166" : "#887ababf"
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    MaterialSymbol {
                        visible: card.toggled
                        text: "check"
                        iconSize: 16
                        color: card.labelColor
                    }
                    StyledText {
                        Layout.maximumWidth: card.availableWidth - (card.toggled ? 20 : 0)
                        text: card.text
                        color: card.labelColor
                        elide: Text.ElideRight
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                visible: card.visualFocus
                radius: card.buttonRadius
                color: "transparent"
                border.width: 2
                border.color: card.labelColor
            }
        }
    }
}
