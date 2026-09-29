import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "rounded_corner"
        title: Translation.tr("Borders and gaps")

        HyprlandConfigSpinBox {
            key: "general:border_size"
            icon: "border_style"
            text: Translation.tr("Border size")
            from: 0
            to: 20
        }
        HyprlandConfigSpinBox {
            key: "general:gaps_in"
            icon: "padding"
            text: Translation.tr("Gaps between windows")
            from: 0
            to: 100
        }
        HyprlandConfigSpinBox {
            key: "general:gaps_out"
            icon: "fit_screen"
            text: Translation.tr("Gaps around screen edges")
            from: 0
            to: 100
        }
        HyprlandConfigSpinBox {
            key: "decoration:rounding"
            icon: "rounded_corner"
            text: Translation.tr("Rounding")
            from: 0
            to: 50
        }
        HyprlandConfigSlider {
            key: "decoration:rounding_power"
            buttonIcon: "line_curve"
            text: Translation.tr("Corner shape")
            textWidth: 180
            usePercentTooltip: false
            from: 1
            to: 10
        }
    }

    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Effects")

        ConfigRow {
            uniform: true
            HyprlandConfigSwitch {
                key: "decoration:blur:enabled"
                buttonIcon: "blur_on"
                text: Translation.tr("Blur")
            }
            HyprlandConfigSwitch {
                key: "decoration:shadow:enabled"
                buttonIcon: "shadow"
                text: Translation.tr("Shadows")
            }
        }
        HyprlandConfigSpinBox {
            key: "decoration:blur:size"
            icon: "blur_medium"
            text: Translation.tr("Blur size")
            from: 1
            to: 50
        }
        HyprlandConfigSpinBox {
            key: "decoration:blur:passes"
            icon: "layers"
            text: Translation.tr("Blur passes")
            from: 1
            to: 10
        }
        ConfigRow {
            uniform: true
            HyprlandConfigSwitch {
                key: "decoration:dim_inactive"
                buttonIcon: "brightness_low"
                text: Translation.tr("Dim inactive windows")
            }
            HyprlandConfigSwitch {
                key: "animations:enabled"
                buttonIcon: "animation"
                text: Translation.tr("Animations")
            }
        }
        HyprlandConfigSlider {
            key: "decoration:dim_strength"
            buttonIcon: "contrast"
            text: Translation.tr("Dim strength")
            textWidth: 180
            from: 0
            to: 1
        }
    }

    ContentSection {
        icon: "restart_alt"
        title: Translation.tr("Defaults")

        RippleButtonWithIcon {
            Layout.fillWidth: true
            buttonRadius: Appearance.rounding.small
            materialIcon: "restart_alt"
            mainText: Translation.tr("Reset window options")
            onClicked: HyprlandConfig.resetUserMany([
                "general:border_size", "general:gaps_in", "general:gaps_out",
                "decoration:rounding", "decoration:rounding_power",
                "decoration:blur:enabled", "decoration:blur:size", "decoration:blur:passes",
                "decoration:shadow:enabled", "decoration:dim_inactive", "decoration:dim_strength",
                "animations:enabled"
            ])
        }
    }
}
