import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

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
