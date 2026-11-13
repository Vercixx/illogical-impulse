import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models.hyprland
import qs.modules.settings.bar

ContentPage {
    property bool showMoreSettings: true
    property bool showLayoutSettings: true
    forceWidth: true

    Process {
        id: randomWallProc
        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]
        stdout: SplitParser {
            onRead: data => {
                randomWallProc.status = data.trim();
            }
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    // Wallpaper selection
    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: 340
                implicitHeight: 200
                
                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 360
                            height: 200
                            radius: Appearance.rounding.normal
                        }
                    }
                }
            }

            ColumnLayout {
                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`;
                        randomWallProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_osu_wall.sh`;
                        randomWallProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        text: Translation.tr("Pick wallpaper image on your system")
                    }
                    onClicked: {
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Choose file")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            RowLayout {
                                spacing: 3
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                KeyboardKey {
                                    key: Config.options.cheatsheet.superKey ?? "󰖳"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }
                RippleButtonWithIcon {
                    readonly property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`)
                    enabled: Config.options.background.wallpaperPath !== defaultWallpaperPath
                    Layout.fillWidth: true
                    materialIcon: "restart_alt"
                    mainText: Translation.tr("Default wallpaper")
                    onClicked: {
                        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, defaultWallpaperPath]);
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: false
                    }
                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: true
                    }
                }
            }
        }

        ConfigSwitch {
            visible: /\.(mp4|webm|mkv|avi|mov)$/.test(Config.options.background.wallpaperPath) && layoutOption.shownValue === "lua:drift"
            buttonIcon: "grain"
            text: Translation.tr("Show moving dots on Drift canvas")
            checked: Config.options.background.driftDots
            onCheckedChanged: {
                Config.options.background.driftDots = checked;
            }
            StyledToolTip {
                text: Translation.tr("Helps fight disorientation, since video wallpapers don't move when panning")
            }
        }

        ConfigSelectionArray {
            currentValue: Config.options.appearance.palette.type
            onSelected: newValue => {
                Config.options.appearance.palette.type = newValue;
                Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
            }
            options: [
                {
                    "value": "auto",
                    "displayName": Translation.tr("Auto")
                },
                {
                    "value": "scheme-content",
                    "displayName": Translation.tr("Content")
                },
                {
                    "value": "scheme-expressive",
                    "displayName": Translation.tr("Expressive")
                },
                {
                    "value": "scheme-fidelity",
                    "displayName": Translation.tr("Fidelity")
                },
                {
                    "value": "scheme-fruit-salad",
                    "displayName": Translation.tr("Fruit Salad")
                },
                {
                    "value": "scheme-monochrome",
                    "displayName": Translation.tr("Monochrome")
                },
                {
                    "value": "scheme-neutral",
                    "displayName": Translation.tr("Neutral")
                },
                {
                    "value": "scheme-rainbow",
                    "displayName": Translation.tr("Rainbow")
                },
                {
                    "value": "scheme-tonal-spot",
                    "displayName": Translation.tr("Tonal Spot")
                }
            ]
        }

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bar style")
            BarStyleSelector {}
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => {
                        Config.options.appearance.fakeScreenRounding = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("When not fullscreen"),
                            icon: "fullscreen_exit",
                            value: 2
                        }
                    ]
                }
            }

        }
    }

    ContentSection {
        id: layoutSection
        property bool settingsExpanded: false
        visible: showLayoutSettings

        icon: "view_quilt"
        title: Translation.tr("Window layout")

        ConfigSelectionArray {
            currentValue: layoutOption.shownValue
            onSelected: newValue => HyprlandConfig.setUser("general:layout", newValue)
            options: [
                { "value": "dwindle", "displayName": Translation.tr("Dwindle"), "tooltip": Translation.tr("Uses binary space partitioning to recursively divide your workspace between windows") },
                { "value": "master", "displayName": Translation.tr("Master"), "tooltip": Translation.tr("Dedicates one half of your screen to one window while keeping other ones stacked beside it") },
                { "value": "scrolling", "displayName": Translation.tr("Scrolling"), "tooltip": Translation.tr("Stacks your windows in columns on an infinitely growing tape") },
                { "value": "monocle", "displayName": Translation.tr("Monocle"), "tooltip": Translation.tr("Displays one window at a time, maximizing your available workspace") },
                { "value": "lua:drift", "displayName": Translation.tr("Drift"), "tooltip": Translation.tr("Gets rid of tiling in favor of an infinite 2D canvas your windows can use") }
            ]
            HyprlandConfigOption {
                id: layoutOption
                key: "general:layout"
            }
        }

        RippleButton {
            id: layoutSettingsHeader
            visible: layoutSettingsLoader.sourceComponent !== null
            Layout.fillWidth: true
            implicitHeight: layoutSettingsHeaderRow.implicitHeight + 8 * 2
            font.pixelSize: Appearance.font.pixelSize.small
            onClicked: layoutSection.settingsExpanded = !layoutSection.settingsExpanded

            contentItem: RowLayout {
                id: layoutSettingsHeaderRow
                spacing: 10

                OptionalMaterialSymbol {
                    icon: "tune"
                    iconSize: Appearance.font.pixelSize.larger
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Layout settings")
                    font: layoutSettingsHeader.font
                    color: Appearance.colors.colOnSecondaryContainer
                }
                MaterialSymbol {
                    text: "expand_more"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                    rotation: layoutSection.settingsExpanded ? 180 : 0

                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }
        }

        Revealer {
            Layout.fillWidth: true
            vertical: true
            reveal: layoutSection.settingsExpanded && layoutSettingsLoader.sourceComponent !== null

            Loader {
                id: layoutSettingsLoader
                width: parent.width
                sourceComponent: ({
                        "dwindle": dwindleSettings,
                        "master": masterSettings,
                        "scrolling": scrollingSettings,
                        "lua:drift": driftSettings
                    })[layoutOption.shownValue] ?? null
            }
        }

        Component {
            id: dwindleSettings

            ColumnLayout {
                spacing: 4

                HyprlandConfigSwitch {
                    key: "dwindle:preserve_split"
                    buttonIcon: "splitscreen"
                    text: Translation.tr("Keep split direction")
                }
                HyprlandConfigSwitch {
                    key: "dwindle:smart_split"
                    buttonIcon: "ads_click"
                    text: Translation.tr("Split by cursor position")
                }
                ContentSubsection {
                    title: Translation.tr("New window side")
                    ConfigSelectionArray {
                        currentValue: forceSplitOption.shownValue
                        onSelected: newValue => HyprlandConfig.setUser("dwindle:force_split", newValue)
                        options: [
                            { "value": 0, "displayName": Translation.tr("Follow cursor") },
                            { "value": 1, "displayName": Translation.tr("Left or top") },
                            { "value": 2, "displayName": Translation.tr("Right or bottom") }
                        ]
                        HyprlandConfigOption {
                            id: forceSplitOption
                            key: "dwindle:force_split"
                        }
                    }
                }
            }
        }

        Component {
            id: masterSettings

            ColumnLayout {
                spacing: 4

                HyprlandConfigSlider {
                    key: "master:mfact"
                    buttonIcon: "width"
                    text: Translation.tr("Master size")
                    textWidth: 200
                    from: 0.1
                    to: 0.9
                }
                ContentSubsection {
                    title: Translation.tr("Master position")
                    ConfigSelectionArray {
                        currentValue: orientationOption.shownValue
                        onSelected: newValue => HyprlandConfig.setUser("master:orientation", newValue)
                        options: [
                            { "value": "left", "displayName": Translation.tr("Left") },
                            { "value": "right", "displayName": Translation.tr("Right") },
                            { "value": "top", "displayName": Translation.tr("Top") },
                            { "value": "bottom", "displayName": Translation.tr("Bottom") },
                            { "value": "center", "displayName": Translation.tr("Center") }
                        ]
                        HyprlandConfigOption {
                            id: orientationOption
                            key: "master:orientation"
                        }
                    }
                }
                ContentSubsection {
                    title: Translation.tr("New windows open as")
                    ConfigSelectionArray {
                        currentValue: newStatusOption.shownValue
                        onSelected: newValue => HyprlandConfig.setUser("master:new_status", newValue)
                        options: [
                            { "value": "master", "displayName": Translation.tr("Master") },
                            { "value": "slave", "displayName": Translation.tr("Stack") },
                            { "value": "inherit", "displayName": Translation.tr("Same as focused") }
                        ]
                        HyprlandConfigOption {
                            id: newStatusOption
                            key: "master:new_status"
                        }
                    }
                }
                HyprlandConfigSwitch {
                    key: "master:new_on_top"
                    buttonIcon: "vertical_align_top"
                    text: Translation.tr("New windows at top of stack")
                }
            }
        }

        Component {
            id: scrollingSettings

            ColumnLayout {
                spacing: 4

                HyprlandConfigSlider {
                    key: "scrolling:column_width"
                    buttonIcon: "view_column"
                    text: Translation.tr("Column width")
                    textWidth: 200
                    from: 0.1
                    to: 1
                }
                ContentSubsection {
                    title: Translation.tr("Scroll direction")
                    ConfigSelectionArray {
                        currentValue: directionOption.shownValue
                        onSelected: newValue => HyprlandConfig.setUser("scrolling:direction", newValue)
                        options: [
                            { "value": "right", "displayName": Translation.tr("Right") },
                            { "value": "left", "displayName": Translation.tr("Left") },
                            { "value": "down", "displayName": Translation.tr("Down") },
                            { "value": "up", "displayName": Translation.tr("Up") }
                        ]
                        HyprlandConfigOption {
                            id: directionOption
                            key: "scrolling:direction"
                        }
                    }
                }
                ContentSubsection {
                    title: Translation.tr("Bring focused column into view")
                    ConfigSelectionArray {
                        currentValue: fitMethodOption.shownValue
                        onSelected: newValue => HyprlandConfig.setUser("scrolling:focus_fit_method", newValue)
                        options: [
                            { "value": 0, "displayName": Translation.tr("Center") },
                            { "value": 1, "displayName": Translation.tr("Fit") }
                        ]
                        HyprlandConfigOption {
                            id: fitMethodOption
                            key: "scrolling:focus_fit_method"
                        }
                    }
                }
                HyprlandConfigSwitch {
                    key: "scrolling:fullscreen_on_one_column"
                    buttonIcon: "fit_screen"
                    text: Translation.tr("Single column fills screen")
                }
            }
        }

        Component {
            id: driftSettings

            ColumnLayout {
                spacing: 4

                HyprlandConfigSpinBox {
                    key: "drift:new_width"
                    defaultValue: 60
                    icon: "width"
                    text: Translation.tr("New window width (% of screen)")
                    from: 10
                    to: 100
                }
                HyprlandConfigSpinBox {
                    key: "drift:new_height"
                    defaultValue: 70
                    icon: "height"
                    text: Translation.tr("New window height (% of screen)")
                    from: 10
                    to: 100
                }
                HyprlandConfigSpinBox {
                    key: "drift:recenter_delay"
                    defaultValue: 60
                    icon: "center_focus_strong"
                    text: Translation.tr("Recenter after idle (seconds, 0 = off)")
                    from: 0
                    to: 3600
                    stepSize: 10
                    StyledToolTip {
                        text: Translation.tr("Windows and camera will move closer to the center of the canvas after a set amount of time")
                    }
                }
                HyprlandConfigSpinBox {
                    key: "drift:pan_step"
                    defaultValue: 100
                    icon: "pan_tool"
                    text: Translation.tr("Keyboard pan step (px)")
                    from: 10
                    to: 2000
                    stepSize: 10
                }
                HyprlandConfigSpinBox {
                    key: "drift:nudge_step"
                    defaultValue: 20
                    icon: "open_with"
                    text: Translation.tr("Keyboard move step (px)")
                    from: 1
                    to: 500
                    stepSize: 5
                }
                HyprlandConfigSpinBox {
                    key: "drift:resize_step"
                    defaultValue: 20
                    icon: "open_in_full"
                    text: Translation.tr("Keyboard resize step (px)")
                    from: 1
                    to: 500
                    stepSize: 5
                }
            }
        }
    }

    ContentSection {
        visible: showMoreSettings
        icon: "more_horiz"
        title: Translation.tr("More settings")

        ConfigRow {
            RippleButtonWithIcon {
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "edit"
                mainText: Translation.tr("Open config file")
                onClicked: Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`)
            }
            RippleButtonWithIcon {
                id: copyPathButton
                property bool justCopied: false
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: justCopied ? "check" : "content_copy"
                mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")
                onClicked: {
                    copyPathButton.justCopied = true
                    Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                    revertTextTimer.restart();
                }

                Timer {
                    id: revertTextTimer
                    interval: 1500
                    onTriggered: {
                        copyPathButton.justCopied = false
                    }
                }
            }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "settings"
                mainText: Translation.tr("KDE System Settings")
                onClicked: {
                    Hyprland.dispatch("hl.dsp.exec_cmd('systemsettings')")
                    root.close()
                }
            }
        }
    }
}
