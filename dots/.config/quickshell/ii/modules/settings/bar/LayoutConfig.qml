import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

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
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {

            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                enabled: Config.options.bar.cornerStyle === 1
                buttonIcon: "shadow"
                text: Translation.tr("Shadow (Float style)")
                checked: Config.options.bar.floatStyleShadow
                onCheckedChanged: {
                    Config.options.bar.floatStyleShadow = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "rectangle"
                text: Translation.tr("Show background")
                checked: Config.options.bar.showBackground
                onCheckedChanged: {
                    Config.options.bar.showBackground = checked;
                }
            }
        }
        ConfigSwitch {
            buttonIcon: "more_horiz"
            text: Translation.tr("Verbose")
            checked: Config.options.bar.verbose
            onCheckedChanged: {
                Config.options.bar.verbose = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show date next to the clock and media title in the middle")
            }
        }
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Top-left icon (\"distro\" or icon name from assets/icons)")
            text: Config.options.bar.topLeftIcon
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.bar.topLeftIcon = text;
            }
        }
        ConfigStringList {
            placeholderText: Translation.tr("Show only on these monitors, comma-separated (empty = all)")
            value: Config.options.bar.screenList
            onEdited: list => {
                Config.options.bar.screenList = list;
            }
        }
    }

    ContentSection {
        icon: "visibility_off"
        title: Translation.tr("Auto-hide")
        enabled: Config.options.bar.autoHide.enable

        ConfigSwitch {
            buttonIcon: "move_down"
            text: Translation.tr("Push windows")
            checked: Config.options.bar.autoHide.pushWindows
            onCheckedChanged: {
                Config.options.bar.autoHide.pushWindows = checked;
            }
        }
        ConfigSpinBox {
            icon: "height"
            text: Translation.tr("Hover region (px)")
            value: Config.options.bar.autoHide.hoverRegionWidth
            from: 1
            to: 20
            stepSize: 1
            onValueChanged: {
                Config.options.bar.autoHide.hoverRegionWidth = value;
            }
        }
        ConfigSwitch {
            buttonIcon: "keyboard_command_key"
            text: Translation.tr("Show when pressing Super")
            checked: Config.options.bar.autoHide.showWhenPressingSuper.enable
            onCheckedChanged: {
                Config.options.bar.autoHide.showWhenPressingSuper.enable = checked;
            }
        }
        ConfigSpinBox {
            enabled: Config.options.bar.autoHide.showWhenPressingSuper.enable
            icon: "timer"
            text: Translation.tr("Delay (ms)")
            value: Config.options.bar.autoHide.showWhenPressingSuper.delay
            from: 0
            to: 1000
            stepSize: 20
            onValueChanged: {
                Config.options.bar.autoHide.showWhenPressingSuper.delay = value;
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
