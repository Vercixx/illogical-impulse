import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "dashboard"
        title: Translation.tr("Panel family")

        ConfigSelectionArray {
            currentValue: Config.options.panelFamily
            onSelected: newValue => {
                Config.options.panelFamily = newValue;
            }
            options: [
                {
                    displayName: "illogical-impulse",
                    icon: "toast",
                    value: "ii"
                },
                {
                    displayName: Translation.tr("Waffle (Windows-like)"),
                    icon: "window",
                    value: "waffle"
                }
            ]
        }
    }

    Loader {
        Layout.fillWidth: true
        active: Config.options.panelFamily === "waffle"
        visible: active
        sourceComponent: ContentSection {
            icon: "window"
            title: Translation.tr("Waffle")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: Translation.tr("Taskbar at bottom")
                    checked: Config.options.waffles.bar.bottom
                    onCheckedChanged: {
                        Config.options.waffles.bar.bottom = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "format_align_left"
                    text: Translation.tr("Left-align apps")
                    checked: Config.options.waffles.bar.leftAlignApps
                    onCheckedChanged: {
                        Config.options.waffles.bar.leftAlignApps = checked;
                    }
                }
            }
            ConfigSwitch {
                buttonIcon: "calendar_month"
                text: Translation.tr("Two-letter weekday names in calendar")
                checked: Config.options.waffles.calendar.force2CharDayOfWeek
                onCheckedChanged: {
                    Config.options.waffles.calendar.force2CharDayOfWeek = checked;
                }
            }
            ContentSubsection {
                title: Translation.tr("Tweaks")
                tooltip: Translation.tr("Turn off to match Windows more closely, janky spots included")
                ConfigSwitch {
                    buttonIcon: "toggle_on"
                    text: Translation.tr("Fix switch handle position")
                    checked: Config.options.waffles.tweaks.switchHandlePositionFix
                    onCheckedChanged: {
                        Config.options.waffles.tweaks.switchHandlePositionFix = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Smoother menu animations")
                    checked: Config.options.waffles.tweaks.smootherMenuAnimations
                    onCheckedChanged: {
                        Config.options.waffles.tweaks.smootherMenuAnimations = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "search"
                    text: Translation.tr("Smoother search bar")
                    checked: Config.options.waffles.tweaks.smootherSearchBar
                    onCheckedChanged: {
                        Config.options.waffles.tweaks.smootherSearchBar = checked;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "mouse"
        title: Translation.tr("Scrolling")

        ConfigSwitch {
            buttonIcon: "speed"
            text: Translation.tr("Faster touchpad scrolling")
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onCheckedChanged: {
                Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "mouse"
                text: Translation.tr("Mouse factor")
                value: Config.options.interactions.scrolling.mouseScrollFactor
                from: 10
                to: 1000
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.mouseScrollFactor = value;
                }
            }
            ConfigSpinBox {
                icon: "touch_app"
                text: Translation.tr("Touchpad factor")
                value: Config.options.interactions.scrolling.touchpadScrollFactor
                from: 10
                to: 2000
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.touchpadScrollFactor = value;
                }
            }
        }
        ConfigSpinBox {
            icon: "tune"
            text: Translation.tr("Mouse detection threshold (delta)")
            value: Config.options.interactions.scrolling.mouseScrollDeltaThreshold
            from: 1
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.interactions.scrolling.mouseScrollDeltaThreshold = value;
            }
            StyledToolTip {
                text: Translation.tr("Scroll deltas at or above this count as mouse wheel, below as touchpad")
            }
        }
    }

    ContentSection {
        icon: "build"
        title: Translation.tr("Workarounds")

        ConfigSwitch {
            buttonIcon: "border_right"
            text: Translation.tr("Dead pixel workaround")
            checked: Config.options.interactions.deadPixelWorkaround.enable
            onCheckedChanged: {
                Config.options.interactions.deadPixelWorkaround.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hyprland leaves out 1 pixel on the right for interactions")
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "notifications_off"
                text: Translation.tr("Kill other notification daemons")
                checked: Config.options.conflictKiller.autoKillNotificationDaemons
                onCheckedChanged: {
                    Config.options.conflictKiller.autoKillNotificationDaemons = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "shelf_auto_hide"
                text: Translation.tr("Kill other trays")
                checked: Config.options.conflictKiller.autoKillTrays
                onCheckedChanged: {
                    Config.options.conflictKiller.autoKillTrays = checked;
                }
            }
        }
        ConfigSpinBox {
            icon: "hourglass"
            text: Translation.tr("Race condition delay (ms)")
            value: Config.options.hacks.arbitraryRaceConditionDelay
            from: 0
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.hacks.arbitraryRaceConditionDelay = value;
            }
        }
    }
}
