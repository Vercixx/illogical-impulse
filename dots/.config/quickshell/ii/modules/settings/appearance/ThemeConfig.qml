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
    }

    ContentSection {
        icon: "ev_shadow"
        title: Translation.tr("Transparency")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
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
