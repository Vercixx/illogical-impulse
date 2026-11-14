pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""
    readonly property string appIconName: AppSearch.guessIcon(player?.desktopEntry || player?.identity)
    readonly property color scrimColor: ColorUtils.mix(Appearance.colors.colLayer0, root.artDominantColor, 0.75)
    readonly property color contentColor: ColorUtils.mix(Appearance.colors.colOnLayer0, root.artDominantColor, 0.85)

    function cycleOutputDevice() {
        const devices = Audio.outputDevices;
        const current = devices.findIndex(node => node.id === Audio.sink?.id);
        Audio.setDefaultSink(devices[(current + 1) % devices.length]);
    }

    function cycleLoopState() {
        if (root.player.loopState === MprisLoopState.None)
            root.player.loopState = MprisLoopState.Playlist;
        else if (root.player.loopState === MprisLoopState.Playlist)
            root.player.loopState = MprisLoopState.Track;
        else
            root.player.loopState = MprisLoopState.None;
    }

    component ControlButton: RippleButton {
        id: controlButton
        property string iconName
        property bool dimmed: false

        implicitWidth: 36
        implicitHeight: 36
        buttonRadius: Appearance.rounding.full
        colBackground: ColorUtils.transparentize(root.contentColor, 1)
        colBackgroundHover: ColorUtils.transparentize(root.contentColor, 0.88)
        colRipple: ColorUtils.transparentize(root.contentColor, 0.75)

        contentItem: MaterialSymbol {
            iconSize: 26
            horizontalAlignment: Text.AlignHCenter
            color: root.contentColor
            opacity: controlButton.dimmed ? 0.45 : 1
            text: controlButton.iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    Timer { // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged()
        }
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: blendedColors.colLayer0
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        StyledImage {
            id: art
            anchors.fill: parent
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: blendedColors.colPrimary
                brightness: Appearance.m3colors.darkmode ? -0.3 : 0.3
            }
        }

        Rectangle { // Scrim
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: ColorUtils.transparentize(root.scrimColor, 0.15)
                }
                GradientStop {
                    position: 1
                    color: ColorUtils.transparentize(root.scrimColor, 0.45)
                }
            }
        }

        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            live: root.player?.isPlaying
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    implicitWidth: 28
                    implicitHeight: 28

                    AppIcon {
                        anchors.fill: parent
                        visible: AppSearch.iconExists(root.appIconName)
                        source: Quickshell.iconPath(root.appIconName)
                        implicitSize: 28
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: !AppSearch.iconExists(root.appIconName)
                        iconSize: Appearance.font.pixelSize.hugeass
                        fill: 1
                        color: root.contentColor
                        text: "music_note"
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RippleButton {
                    id: outputChip
                    Layout.maximumWidth: 200
                    implicitHeight: 32
                    horizontalPadding: 12
                    enabled: Audio.outputDevices.length > 1
                    buttonRadius: Appearance.rounding.full
                    colBackground: blendedColors.colPrimary
                    colBackgroundHover: blendedColors.colPrimaryHover
                    colRipple: blendedColors.colPrimaryActive
                    releaseAction: () => root.cycleOutputDevice()

                    contentItem: RowLayout {
                        spacing: 6

                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.larger
                            color: blendedColors.colOnPrimary
                            text: "media_output"
                        }
                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: blendedColors.colOnPrimary
                            elide: Text.ElideRight
                            text: Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : Translation.tr("Unknown")
                            animateChange: true
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: root.contentColor
                        elide: Text.ElideRight
                        text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                        animateChange: true
                        animationDistanceX: 6
                        animationDistanceY: 0
                    }
                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: root.player?.trackArtist ?? ""
                        animateChange: true
                        animationDistanceX: 6
                        animationDistanceY: 0
                    }
                }

                RippleButton {
                    id: playPauseButton
                    property real size: 56
                    implicitWidth: size
                    implicitHeight: size
                    downAction: () => root.player.togglePlaying();

                    buttonRadius: root.player?.isPlaying ? Appearance?.rounding.large : size / 2
                    colBackground: blendedColors.colPrimary
                    colBackgroundHover: blendedColors.colPrimaryHover
                    colRipple: blendedColors.colPrimaryActive

                    contentItem: MaterialSymbol {
                        iconSize: Appearance.font.pixelSize.hugeass
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnPrimary
                        text: root.player?.isPlaying ? "pause" : "play_arrow"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.leftMargin: -8
                Layout.rightMargin: -8
                spacing: 2

                ControlButton {
                    iconName: "skip_previous"
                    downAction: () => root.player?.previous()
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                    Loader {
                        id: sliderLoader
                        anchors.fill: parent
                        active: root.player?.canSeek ?? false
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            highlightColor: root.contentColor
                            trackColor: ColorUtils.transparentize(root.contentColor, 0.7)
                            handleColor: root.contentColor
                            value: root.player?.position / root.player?.length
                            tooltipContent: `${StringUtils.friendlyTimeForSeconds(value * (root.player?.length ?? 0))} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                            onMoved: {
                                root.player.position = value * root.player.length;
                            }
                        }
                    }

                    Loader {
                        id: progressBarLoader
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                        }
                        active: !(root.player?.canSeek ?? false)
                        sourceComponent: StyledProgressBar {
                            wavy: root.player?.isPlaying ?? false
                            highlightColor: root.contentColor
                            trackColor: ColorUtils.transparentize(root.contentColor, 0.7)
                            value: root.player?.position / root.player?.length
                        }
                    }
                }

                ControlButton {
                    iconName: "skip_next"
                    downAction: () => root.player?.next()
                }

                ControlButton {
                    visible: root.player?.shuffleSupported ?? false
                    iconName: "shuffle"
                    dimmed: !root.player?.shuffle
                    downAction: () => root.player.shuffle = !root.player.shuffle
                }

                ControlButton {
                    visible: root.player?.loopSupported ?? false
                    iconName: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                    dimmed: root.player?.loopState === MprisLoopState.None
                    downAction: () => root.cycleLoopState()
                }
            }
        }
    }
}
