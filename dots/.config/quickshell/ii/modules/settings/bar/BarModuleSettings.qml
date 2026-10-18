import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Per-module options shown when a module is clicked in the layout editor
QtObject {
    id: root

    function component(moduleId) {
        return root[moduleId] ?? null;
    }

    property Component leftSidebarButton: Component {
        ColumnLayout {
            spacing: 4
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Top-left icon (\"distro\" or icon name from assets/icons)")
                text: Config.options.bar.topLeftIcon
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.bar.topLeftIcon = text;
                }
            }
        }
    }

    property Component resources: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "planner_review"
                text: Translation.tr("Always show CPU")
                checked: Config.options.bar.resources.alwaysShowCpu
                onCheckedChanged: {
                    Config.options.bar.resources.alwaysShowCpu = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "swap_horiz"
                text: Translation.tr("Always show swap")
                checked: Config.options.bar.resources.alwaysShowSwap
                onCheckedChanged: {
                    Config.options.bar.resources.alwaysShowSwap = checked;
                }
            }
            ContentSubsectionLabel {
                text: Translation.tr("Warning thresholds (%)")
            }
            ConfigSpinBox {
                icon: "memory"
                text: Translation.tr("RAM")
                value: Config.options.bar.resources.memoryWarningThreshold
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.bar.resources.memoryWarningThreshold = value;
                }
            }
            ConfigSpinBox {
                icon: "swap_horiz"
                text: Translation.tr("Swap")
                value: Config.options.bar.resources.swapWarningThreshold
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.bar.resources.swapWarningThreshold = value;
                }
            }
            ConfigSpinBox {
                icon: "planner_review"
                text: Translation.tr("CPU")
                value: Config.options.bar.resources.cpuWarningThreshold
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.bar.resources.cpuWarningThreshold = value;
                }
            }
        }
    }

    property Component clock: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "calendar_month"
                text: Translation.tr("Show date")
                checked: Config.options.bar.clock.showDate
                onCheckedChanged: {
                    Config.options.bar.clock.showDate = checked;
                }
            }
        }
    }

    property Component media: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "title"
                text: Translation.tr("Show track title")
                checked: Config.options.bar.media.showTitle
                onCheckedChanged: {
                    Config.options.bar.media.showTitle = checked;
                }
            }
        }
    }

    property Component workspaces: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "counter_1"
                text: Translation.tr('Always show numbers')
                checked: Config.options.bar.workspaces.alwaysShowNumbers
                onCheckedChanged: {
                    Config.options.bar.workspaces.alwaysShowNumbers = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "award_star"
                text: Translation.tr('Show app icons')
                checked: Config.options.bar.workspaces.showAppIcons
                onCheckedChanged: {
                    Config.options.bar.workspaces.showAppIcons = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colors"
                text: Translation.tr('Tint app icons')
                checked: Config.options.bar.workspaces.monochromeIcons
                onCheckedChanged: {
                    Config.options.bar.workspaces.monochromeIcons = checked;
                }
            }
            ConfigSpinBox {
                icon: "view_column"
                text: Translation.tr("Workspaces shown")
                value: Config.options.bar.workspaces.shown
                from: 1
                to: 30
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.workspaces.shown = value;
                }
            }
            ConfigSpinBox {
                icon: "touch_long"
                text: Translation.tr("Number show delay when pressing Super (ms)")
                value: Config.options.bar.workspaces.showNumberDelay
                from: 0
                to: 1000
                stepSize: 50
                onValueChanged: {
                    Config.options.bar.workspaces.showNumberDelay = value;
                }
            }
            ContentSubsection {
                title: Translation.tr("Number style")
                ConfigSelectionArray {
                    currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                    onSelected: newValue => {
                        Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                    }
                    options: [
                        {
                            displayName: Translation.tr("Normal"),
                            icon: "timer_10",
                            value: '[]'
                        },
                        {
                            displayName: Translation.tr("Han chars"),
                            icon: "square_dot",
                            value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                        },
                        {
                            displayName: Translation.tr("Roman"),
                            icon: "account_balance",
                            value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                        }
                    ]
                }
            }
            ConfigSwitch {
                buttonIcon: "font_download"
                text: Translation.tr("Use Nerd Font for numbers")
                checked: Config.options.bar.workspaces.useNerdFont
                onCheckedChanged: {
                    Config.options.bar.workspaces.useNerdFont = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Lets you put Nerd Font icons in the number map in the config file")
                }
            }
        }
    }

    property Component utilButtons: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
    }

    property Component sysTray: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr('Make icons pinned by default')
                checked: Config.options.tray.invertPinnedItems
                onCheckedChanged: {
                    Config.options.tray.invertPinnedItems = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colors"
                text: Translation.tr('Tint icons')
                checked: Config.options.tray.monochromeIcons
                onCheckedChanged: {
                    Config.options.tray.monochromeIcons = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "filter_alt"
                text: Translation.tr('Hide passive items')
                checked: Config.options.tray.filterPassive
                onCheckedChanged: {
                    Config.options.tray.filterPassive = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "badge"
                text: Translation.tr('Show item IDs in tooltips')
                checked: Config.options.tray.showItemId
                onCheckedChanged: {
                    Config.options.tray.showItemId = checked;
                }
            }
        }
    }

    property Component systemIndicators: Component {
        ColumnLayout {
            spacing: 4
            ConfigSwitch {
                buttonIcon: "counter_2"
                text: Translation.tr("Unread indicator: show count")
                checked: Config.options.bar.indicators.notifications.showUnreadCount
                onCheckedChanged: {
                    Config.options.bar.indicators.notifications.showUnreadCount = checked;
                }
            }
        }
    }
}
