pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot

        required property var modelData

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        property int workspaceChunkSize: Config?.options.bar.workspaces.shown ?? 10
        property int totalWorkspaces: Math.ceil(lastWorkspaceId / workspaceChunkSize) * workspaceChunkSize
        // Wallpaper
        readonly property bool wallpaperIsVideo: Wallpapers.isVideo
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        readonly property bool filterWallpapers: Config.options.workSafety.enable.wallpaper && CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords)
        function hideWallpaper(path: string): bool {
            return filterWallpapers && CF.StringUtils.stringListContainsSubstring(path.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords);
        }
        readonly property bool wallpaperSafetyTriggered: hideWallpaper(wallpaperPath)
        readonly property real wallpaperZoom: Config.options.background.parallax.workspaceZoom

        readonly property bool driftCanvas: Drift.activeOn(monitor?.activeWorkspace?.id ?? -1)
        readonly property bool driftActive: driftCanvas && !GlobalStates.screenLocked
        readonly property real driftWallpaperFactor: 0.15 // Mb make it configurable later
        property real driftCamX: driftCanvas ? Drift.cameraFor(monitor.activeWorkspace.id).x : 0
        property real driftCamY: driftCanvas ? Drift.cameraFor(monitor.activeWorkspace.id).y : 0
        function wrap(value: real, period: real): real {
            return ((value % period) + period) % period;
        }
        // Make sure it matches general.lua, or panning looks weird
        Behavior on driftCamX {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }
        Behavior on driftCamY {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }
        // Colors
        readonly property bool lockRevealed: GlobalStates.screenLocked && GlobalStates.screenLockRevealed
        property bool shouldBlur: (lockRevealed && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return shouldBlur ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Lock reveal transition
        property real lockZoom: lockRevealed ? Config.options.lock.blur.extraZoom : 1
        Behavior on lockZoom {
            animation: Appearance.animation.lockReveal.numberAnimation.createObject(this)
        }

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        // Bottom until the lock slide ends; flipping layers on reveal makes the wallpaper flash
        property bool lockLayerReached: false
        Timer {
            id: lockLayerTimer
            interval: Appearance.animation.elementMove.duration
            onTriggered: bgRoot.lockLayerReached = GlobalStates.screenLocked
        }
        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                bgRoot.lockLayerReached = false;
                if (GlobalStates.screenLocked) lockLayerTimer.restart();
            }
        }
        WlrLayershell.layer: lockLayerReached ? WlrLayer.Overlay : WlrLayer.Bottom
        // WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Item {
            anchors.fill: parent

            // Wallpaper
            WallpaperTransition {
                id: wallpaperView
                anchors.fill: parent
                readonly property string imagesPath: CF.FileUtils.trimFileProtocol(`${Directories.assetsPath}/images`)
                readonly property string seamlessPath: `${imagesPath}/default_wallpaper_drift.png`
                readonly property real textureScale: Screen.devicePixelRatio * bgRoot.wallpaperZoom
                readonly property real workspaceFraction: {
                    if (bgRoot.totalWorkspaces <= 1) return 0.5;
                    const index = (bgRoot.monitor?.activeWorkspace?.id ?? 1) - 1;
                    return Math.max(0, Math.min(1, index / (bgRoot.totalWorkspaces - 1)));
                }
                readonly property real sidebarOffset: {
                    if (!Config.options.background.parallax.enableSidebar) return 0;
                    return (GlobalStates.sidebarRightOpen - GlobalStates.sidebarLeftOpen) * bgRoot.wallpaperZoom / bgRoot.workspaceChunkSize / 2;
                }
                path: {
                    if (bgRoot.wallpaperSafetyTriggered || (bgRoot.wallpaperIsVideo && !blurLoader.active)) return "";
                    if (bgRoot.driftActive && bgRoot.wallpaperPath === `${imagesPath}/default_wallpaper.png`) return seamlessPath;
                    return bgRoot.wallpaperPath;
                }
                effect: Wallpapers.transition
                direction: Wallpapers.transitionDirection
                duration: Wallpapers.transitionDuration
                visible: !bgRoot.wallpaperIsVideo && !bgRoot.wallpaperSafetyTriggered && !(blurLoader.active && blurLoader.opacity === 1)

                imageComponent: Image {
                    id: wallpaper
                    readonly property real coverScale: Math.max(wallpaperView.width / Math.max(1, implicitWidth), wallpaperView.height / Math.max(1, implicitHeight)) * bgRoot.wallpaperZoom
                    readonly property bool vertical: Config.options.background.parallax.vertical || (Config.options.background.parallax.autoVertical && implicitHeight > implicitWidth)
                    property real fractionX: {
                        const fraction = Config.options.background.parallax.enableWorkspace && !vertical ? wallpaperView.workspaceFraction : 0.5;
                        return Math.max(0, Math.min(1, fraction + wallpaperView.sidebarOffset));
                    }
                    property real fractionY: Config.options.background.parallax.enableWorkspace && vertical ? wallpaperView.workspaceFraction : 0.5
                    Behavior on fractionX { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    Behavior on fractionY { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                    readonly property string filePath: decodeURIComponent(CF.FileUtils.trimFileProtocol(source))
                    readonly property bool seamless: filePath === wallpaperView.seamlessPath
                    visible: !bgRoot.hideWallpaper(filePath)
                    asynchronous: true
                    retainWhileLoading: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(wallpaperView.width * wallpaperView.textureScale, wallpaperView.height * wallpaperView.textureScale)
                    smooth: bgRoot.driftActive
                    scale: bgRoot.lockZoom
                    width: Math.max(1, implicitWidth * coverScale)
                    height: Math.max(1, implicitHeight * coverScale)
                    x: bgRoot.driftActive ? -bgRoot.wrap((width - wallpaperView.width) / 2 + bgRoot.driftCamX * bgRoot.driftWallpaperFactor, width * 2)
                        : (wallpaperView.width - width) * (width < wallpaperView.width ? 0.5 : fractionX)
                    y: bgRoot.driftActive ? -bgRoot.wrap((height - wallpaperView.height) / 2 + bgRoot.driftCamY * bgRoot.driftWallpaperFactor, height * 2)
                        : (wallpaperView.height - height) * (height < wallpaperView.height ? 0.5 : fractionY)

                    Repeater {
                        model: bgRoot.driftActive && wallpaper.status === Image.Ready ? 8 : 0
                        Image {
                            required property int index
                            readonly property int column: (index + 1) % 3
                            readonly property int row: Math.floor((index + 1) / 3)
                            x: column * width
                            y: row * height
                            width: wallpaper.width
                            height: wallpaper.height
                            source: wallpaper.source
                            sourceSize: wallpaper.sourceSize
                            fillMode: Image.PreserveAspectCrop
                            mirror: !wallpaper.seamless && column % 2 === 1
                            mirrorVertically: !wallpaper.seamless && row % 2 === 1
                        }
                    }
                }
            }

            Loader {
                active: bgRoot.driftActive && bgRoot.wallpaperIsVideo && Config.options.background.driftDots
                sourceComponent: Canvas {
                    id: driftDots
                    readonly property real spacing: 64
                    readonly property color dotColor: CF.ColorUtils.transparentize(bgRoot.colText, 0.6)

                    x: -bgRoot.wrap(bgRoot.driftCamX, spacing)
                    y: -bgRoot.wrap(bgRoot.driftCamY, spacing)
                    width: bgRoot.screen.width + spacing
                    height: bgRoot.screen.height + spacing

                    onDotColorChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = driftDots.dotColor;
                        ctx.beginPath();
                        for (let x = driftDots.spacing / 2; x < width; x += driftDots.spacing) {
                            for (let y = driftDots.spacing / 2; y < height; y += driftDots.spacing) {
                                ctx.moveTo(x, y);
                                ctx.arc(x, y, 2, 0, 2 * Math.PI);
                            }
                        }
                        ctx.fill();
                    }
                }
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || opacity > 0)
                anchors.fill: wallpaperView
                opacity: bgRoot.lockRevealed ? 1 : 0
                Behavior on opacity {
                    animation: Appearance.animation.lockReveal.numberAnimation.createObject(this)
                }
                sourceComponent: GaussianBlur {
                    source: wallpaperView
                    radius: Config.options.lock.blur.radius
                    samples: radius * 2 + 1

                    Rectangle {
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            Loader {
                active: bgRoot.driftActive
                x: -bgRoot.driftCamX
                y: -bgRoot.driftCamY
                sourceComponent: Item {
                    Repeater {
                        model: Drift.bookmarksFor(bgRoot.monitor.activeWorkspace.id)
                        delegate: DriftBookmarkPin {
                            required property var modelData
                            slot: modelData.slot
                            x: Math.round(modelData.x - bgRoot.monitor.x - width / 2)
                            y: Math.round(modelData.y - bgRoot.monitor.y - height / 2)
                            opacity: 0.85
                        }
                    }
                }
            }

            WidgetCanvas {
                id: widgetCanvas
                width: parent.width
                height: parent.height
                function offset(image: Image): point {
                    if (!image) return Qt.point(0, 0);
                    return Qt.point(image.x - (width - image.width) / 2, image.y - (height - image.height) / 2);
                }
                readonly property real parallaxFactor: GlobalStates.screenLocked ? 0 : Config.options.background.parallax.widgetsFactor / bgRoot.wallpaperZoom
                readonly property point currentOffset: offset(wallpaperView.currentImage)
                readonly property point nextOffset: offset(wallpaperView.incomingImage)
                x: bgRoot.driftActive ? -bgRoot.driftCamX : (currentOffset.x + (nextOffset.x - currentOffset.x) * wallpaperView.progress) * parallaxFactor
                y: bgRoot.driftActive ? -bgRoot.driftCamY : (currentOffset.y + (nextOffset.y - currentOffset.y) * wallpaperView.progress) * parallaxFactor

                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.weather.enable
                    sourceComponent: WeatherWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.clock.enable
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }
            }
        }
    }
}
