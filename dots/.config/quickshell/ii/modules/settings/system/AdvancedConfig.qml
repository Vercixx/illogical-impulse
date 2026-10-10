import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models.hyprland
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
        icon: "view_quilt"
        title: Translation.tr("Compositor")

        ContentSubsection {
            title: Translation.tr("Window layout")
            ConfigSelectionArray {
                currentValue: layoutOption.shownValue
                onSelected: newValue => HyprlandConfig.setUser("general:layout", newValue)
                options: [
                    { "value": "dwindle", "displayName": Translation.tr("Dwindle") },
                    { "value": "master", "displayName": Translation.tr("Master") }
                ]
                HyprlandConfigOption {
                    id: layoutOption
                    key: "general:layout"
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Variable refresh rate")
            ConfigSelectionArray {
                currentValue: vrrOption.shownValue
                onSelected: newValue => HyprlandConfig.setUser("misc:vrr", newValue)
                options: [
                    { "value": 0, "displayName": Translation.tr("Off") },
                    { "value": 1, "displayName": Translation.tr("On") },
                    { "value": 2, "displayName": Translation.tr("Fullscreen only") },
                    { "value": 3, "displayName": Translation.tr("Fullscreen games and video") }
                ]
                HyprlandConfigOption {
                    id: vrrOption
                    key: "misc:vrr"
                }
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

    ContentSection {
        id: greeterSection
        icon: "login"
        title: Translation.tr("Login screen")

        readonly property string installScript: `${FileUtils.trimFileProtocol(Directories.config)}/quickshell/ii-greeter/install.sh`
        property bool available: false
        property bool installed: false
        property string status: ""

        function run(args) {
            greeterSection.status = "";
            greeterProc.command = ["pkexec", greeterSection.installScript, ...args];
            greeterProc.running = true;
        }

        Process {
            id: greeterCheckProc
            running: true
            command: ["sh", "-c", "test -x \"$1\" && echo available; test -d /usr/local/share/ii-greeter && echo installed", "sh", greeterSection.installScript]
            stdout: StdioCollector {
                onStreamFinished: {
                    greeterSection.available = text.includes("available");
                    greeterSection.installed = text.includes("installed");
                }
            }
        }

        Process {
            id: greeterProc
            stdout: SplitParser {
                onRead: data => greeterSection.status = data.trim()
            }
            stderr: SplitParser {
                onRead: data => greeterSection.status = data.trim()
            }
            onExited: (exitCode, exitStatus) => greeterCheckProc.running = true
        }

        NoticeBox {
            Layout.fillWidth: true
            text: greeterSection.status || (greeterSection.available
                ? Translation.tr("A greetd frontend styled after illogical-impulse. You'll need to install and enable `greetd` manually")
                : Translation.tr("Greeter files not found. Re-run the dotfiles installer."))

            RippleButtonWithIcon {
                enabled: greeterSection.available && !greeterProc.running
                materialIcon: "download"
                mainText: greeterSection.installed ? Translation.tr("Update greeter") : Translation.tr("Install greeter")
                onClicked: greeterSection.run([])
            }
            RippleButtonWithIcon {
                visible: greeterSection.installed
                enabled: greeterSection.available && !greeterProc.running
                materialIcon: "delete"
                mainText: Translation.tr("Uninstall greeter")
                onClicked: greeterSection.run(["uninstall"])
            }
            RippleButtonWithIcon {
            	materialIcon: "auto_stories"
            	mainText: Translation.tr("Open greeter repo")
            	onClicked: Qt.openUrlExternally("https://github.com/Vercixx/ii-greeter")
            }
        }
    }
}
