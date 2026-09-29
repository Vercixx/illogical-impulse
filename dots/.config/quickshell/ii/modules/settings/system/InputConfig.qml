import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.models.hyprland
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "mouse"
        title: Translation.tr("Mouse")

        ContentSubsection {
            title: Translation.tr("Focus follows mouse")
            ConfigSelectionArray {
                currentValue: followMouse.shownValue
                onSelected: newValue => HyprlandConfig.setUser("input:follow_mouse", newValue)
                options: [
                    { "value": 0, "displayName": Translation.tr("Off") },
                    { "value": 1, "displayName": Translation.tr("Always") },
                    { "value": 2, "displayName": Translation.tr("Keyboard stays") },
                    { "value": 3, "displayName": Translation.tr("Click to focus") }
                ]
                HyprlandConfigOption {
                    id: followMouse
                    key: "input:follow_mouse"
                }
            }
        }
        HyprlandConfigSlider {
            key: "input:sensitivity"
            buttonIcon: "speed"
            text: Translation.tr("Pointer speed")
            textWidth: 180
            usePercentTooltip: false
            from: -1
            to: 1
        }
    }

    ContentSection {
        icon: "touchpad_mouse"
        title: Translation.tr("Touchpad")

        ConfigRow {
            uniform: true
            HyprlandConfigSwitch {
                key: "input:touchpad:natural_scroll"
                buttonIcon: "swap_vert"
                text: Translation.tr("Natural scrolling")
            }
            HyprlandConfigSwitch {
                key: "input:touchpad:disable_while_typing"
                buttonIcon: "keyboard"
                text: Translation.tr("Disable while typing")
            }
        }
    }

    ContentSection {
        icon: "restart_alt"
        title: Translation.tr("Defaults")

        RippleButtonWithIcon {
            Layout.fillWidth: true
            buttonRadius: Appearance.rounding.small
            materialIcon: "restart_alt"
            mainText: Translation.tr("Reset input options")
            onClicked: HyprlandConfig.resetUserMany([
                "input:follow_mouse", "input:sensitivity",
                "input:touchpad:natural_scroll", "input:touchpad:disable_while_typing"
            ])
        }
    }
}
