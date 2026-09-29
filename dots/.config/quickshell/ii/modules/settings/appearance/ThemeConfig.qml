import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "palette"
        title: Translation.tr("Colors")

        ContentSubsection {
            title: Translation.tr("Palette")
            ConfigSelectionArray {
                currentValue: Config.options.appearance.palette.type
                onSelected: newValue => {
                    Config.options.appearance.palette.type = newValue;
                    Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
                }
                options: [
                    { "value": "auto", "displayName": Translation.tr("Auto") },
                    { "value": "scheme-content", "displayName": Translation.tr("Content") },
                    { "value": "scheme-expressive", "displayName": Translation.tr("Expressive") },
                    { "value": "scheme-fidelity", "displayName": Translation.tr("Fidelity") },
                    { "value": "scheme-fruit-salad", "displayName": Translation.tr("Fruit Salad") },
                    { "value": "scheme-monochrome", "displayName": Translation.tr("Monochrome") },
                    { "value": "scheme-neutral", "displayName": Translation.tr("Neutral") },
                    { "value": "scheme-rainbow", "displayName": Translation.tr("Rainbow") },
                    { "value": "scheme-tonal-spot", "displayName": Translation.tr("Tonal Spot") }
                ]
            }
        }

        ConfigColorPicker {
            Layout.fillWidth: true
            text: Translation.tr("Accent color")
            value: Config.options.appearance.palette.accentColor
            onPicked: color => {
                Config.options.appearance.palette.accentColor = color;
                regenerateTimer.restart();
            }
            Timer {
                id: regenerateTimer
                interval: 600
                onTriggered: Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`])
            }
        }

        ConfigSwitch {
            buttonIcon: "format_color_fill"
            text: Translation.tr("Tint background with accent")
            checked: Config.options.appearance.extraBackgroundTint
            onCheckedChanged: {
                Config.options.appearance.extraBackgroundTint = checked;
            }
        }
    }

    ContentSection {
        icon: "ev_shadow"
        title: Translation.tr("Transparency")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.appearance.transparency.enable
                onCheckedChanged: {
                    Config.options.appearance.transparency.enable = checked;
                }
            }
            ConfigSwitch {
                enabled: Config.options.appearance.transparency.enable
                buttonIcon: "auto_awesome"
                text: Translation.tr("Automatic")
                checked: Config.options.appearance.transparency.automatic
                onCheckedChanged: {
                    Config.options.appearance.transparency.automatic = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Picks transparency based on the wallpaper")
                }
            }
        }
        ConfigSlider {
            enabled: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
            buttonIcon: "texture"
            text: Translation.tr("Background")
            value: Config.options.appearance.transparency.backgroundTransparency
            from: 0
            to: 1
            onValueChanged: {
                Config.options.appearance.transparency.backgroundTransparency = value;
            }
        }
        ConfigSlider {
            enabled: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
            buttonIcon: "layers"
            text: Translation.tr("Content areas")
            value: Config.options.appearance.transparency.contentTransparency
            from: 0
            to: 1
            onValueChanged: {
                Config.options.appearance.transparency.contentTransparency = value;
            }
        }
    }

    ContentSection {
        icon: "web_asset"
        title: Translation.tr("Shell windows")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "title"
                text: Translation.tr("Show titlebar")
                checked: Config.options.windows.showTitlebar
                onCheckedChanged: {
                    Config.options.windows.showTitlebar = checked;
                }
            }
            ConfigSwitch {
                enabled: Config.options.windows.showTitlebar
                buttonIcon: "format_align_center"
                text: Translation.tr("Center title")
                checked: Config.options.windows.centerTitle
                onCheckedChanged: {
                    Config.options.windows.centerTitle = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "rounded_corner"
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
