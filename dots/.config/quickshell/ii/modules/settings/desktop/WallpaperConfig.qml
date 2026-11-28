import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "transition_fade"
        title: Translation.tr("Wallpaper transition")

        WallpaperTransitionPicker {
            inView: page.contentY < mapToItem(page.contentItem, 0, height).y
        }
        ContentSubsection {
            id: directionSection
            readonly property string effect: Config.options.background.transition
            readonly property var directions: Wallpapers.directionsFor(effect)
            readonly property string setting: effect === "wipe" ? "wipeDirection" : "slideDirection"
            visible: directions.length > 0
            title: Translation.tr("Direction")
            ConfigSelectionArray {
                currentValue: Config.options.background[directionSection.setting]
                onSelected: value => Config.options.background[directionSection.setting] = value
                options: [
                    { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
                    { displayName: Translation.tr("Right to left"), icon: "arrow_back", value: "left" },
                    { displayName: Translation.tr("Left to right"), icon: "arrow_forward", value: "right" },
                    { displayName: Translation.tr("Up"), icon: "arrow_upward", value: "up" },
                    { displayName: Translation.tr("Down"), icon: "arrow_downward", value: "down" }
                ].filter(option => option.value === "random" || directionSection.directions.includes(option.value))
            }
        }
        ConfigSpinBox {
            icon: "timer"
            text: Translation.tr("Transition duration (ms)")
            from: 0
            to: Wallpapers.maxTransitionDuration
            stepSize: 100
            value: Wallpapers.transitionDuration
            onValueModified: Config.options.background.transitionDuration = value
        }
    }

    ContentSection {
        icon: "wallpaper_slideshow"
        title: Translation.tr("Wallpaper rotation")

        ConfigSwitch {
            buttonIcon: "autorenew"
            text: Translation.tr("Cycle through the current wallpaper folder")
            checked: Config.options.background.rotation.enable
            onCheckedChanged: Config.options.background.rotation.enable = checked
        }

        ConfigSpinBox {
            icon: "timer"
            text: Translation.tr("Interval (minutes)")
            enabled: Config.options.background.rotation.enable
            from: 1
            to: 1440
            value: Config.options.background.rotation.intervalMinutes
            onValueModified: Config.options.background.rotation.intervalMinutes = value
        }
    }

    ContentSection {
        icon: "sync_alt"
        title: Translation.tr("Parallax")

        ConfigSwitch {
            buttonIcon: "unfold_more_double"
            text: Translation.tr("Vertical")
            checked: Config.options.background.parallax.vertical
            onCheckedChanged: {
                Config.options.background.parallax.vertical = checked;
            }
        }
        ConfigSwitch {
            enabled: !Config.options.background.parallax.vertical
            buttonIcon: "screen_rotation"
            text: Translation.tr("Vertical for tall wallpapers")
            checked: Config.options.background.parallax.autoVertical
            onCheckedChanged: {
                Config.options.background.parallax.autoVertical = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "counter_1"
                text: Translation.tr("Depends on workspace")
                checked: Config.options.background.parallax.enableWorkspace
                onCheckedChanged: {
                    Config.options.background.parallax.enableWorkspace = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "side_navigation"
                text: Translation.tr("Depends on sidebars")
                checked: Config.options.background.parallax.enableSidebar
                onCheckedChanged: {
                    Config.options.background.parallax.enableSidebar = checked;
                }
            }
        }
        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Preferred wallpaper zoom (%)")
            value: Config.options.background.parallax.workspaceZoom * 100
            from: 10
            to: 200
            stepSize: 1
            onValueChanged: {
                Config.options.background.parallax.workspaceZoom = value / 100;
            }
        }
        ConfigSpinBox {
            icon: "widgets"
            text: Translation.tr("Widget parallax factor (%)")
            value: Config.options.background.parallax.widgetsFactor * 100
            from: 0
            to: 300
            stepSize: 10
            onValueChanged: {
                Config.options.background.parallax.widgetsFactor = value / 100;
            }
        }
    }

    ContentSection {
        icon: "fullscreen"
        title: Translation.tr("Behavior")

        ConfigSwitch {
            buttonIcon: "hide_image"
            text: Translation.tr("Hide when a window is fullscreen")
            checked: Config.options.background.hideWhenFullscreen
            onCheckedChanged: {
                Config.options.background.hideWhenFullscreen = checked;
            }
        }
    }

    ContentSection {
        icon: "wallpaper_slideshow"
        title: Translation.tr("Wallpaper selector")

        ConfigSwitch {
            buttonIcon: "ad"
            text: Translation.tr('Use system file picker')
            checked: Config.options.wallpaperSelector.useSystemFileDialog
            onCheckedChanged: {
                Config.options.wallpaperSelector.useSystemFileDialog = checked;
            }
        }
    }
}
