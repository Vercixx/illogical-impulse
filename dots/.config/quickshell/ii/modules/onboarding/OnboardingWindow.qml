pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

PanelWindow {
    id: root
    readonly property bool isEonOS: SystemInfo.distroId === "eonos"
    readonly property var pages: [
        ...(root.isEonOS ? [] : [{ "kind": "cover", "component": languagePage }]),
        { "kind": "cover", "component": welcomePage },
        { "kind": "preview", "component": settingsPage, "panels": ["bar", "dock"] },
        { "kind": "cover", "component": askPage },
        { "kind": "cover", "component": tilingPage },
        { "kind": "lesson", "component": appsLesson },
        { "kind": "lesson", "component": windowsLesson },
        { "kind": "lesson", "component": workspacesLesson, "panels": ["workspaces"] },
        { "kind": "lesson", "component": scratchpadLesson, "panels": ["workspaces"] },
        { "kind": "lesson", "component": floatingLesson },
        { "kind": "lesson", "component": fullscreenLesson },
        { "kind": "lesson", "component": shellLesson, "panels": ["sidebars", "overview", "screenshot"] },
        { "kind": "cover", "component": finishPage }
    ]
    property int pageIndex: 0
    property int shownIndex: 0
    readonly property var shownPage: pages[shownIndex]

    function goTo(index) {
        root.pageIndex = index;
        pageSwitchAnimation.restart();
    }
    function next() {
        root.goTo(Math.min(root.pageIndex + 1, root.pages.length - 1));
    }
    function back() {
        root.goTo(Math.max(root.pageIndex - 1, 0));
    }
    function showPage() {
        root.shownIndex = root.pageIndex;
        Onboarding.panels = root.shownPage.panels ?? [];
        GlobalStates.sidebarLeftOpen = false;
        GlobalStates.sidebarRightOpen = false;
        GlobalStates.overviewOpen = false;
    }

    function windowChanged(base, now, key) {
        return Object.keys(now.windows).some(a => base.windows[a] && base.windows[a][key] !== now.windows[a][key]);
    }
    function windowBecame(base, now, key, value) {
        return Object.keys(now.windows).some(a => base.windows[a] && base.windows[a][key] !== value && now.windows[a][key] === value);
    }
    function windowOpened(base, now) {
        return Object.keys(now.windows).some(a => !base.windows[a]);
    }
    // ponytail: classes of the defaults in hyprland/variables.lua; other apps need Skip
    function windowOpenedWithClass(pattern) {
        return (base, now) => Object.keys(now.windows).some(a => !base.windows[a] && pattern.test(now.windows[a].class));
    }
    function windowClosed(base, now) {
        return Object.keys(base.windows).some(a => !now.windows[a]);
    }
    function searchOpenWith(prefix) {
        return GlobalStates.overviewOpen && LauncherSearch.query.startsWith(prefix);
    }

    Component.onCompleted: {
        root.showPage();
        if (Config.options.background.wallpaperPath === "")
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`)]);
    }

    WlrLayershell.namespace: "quickshell:onboarding"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shownPage.kind === "cover" ? WlrKeyboardFocus.Exclusive : root.shownPage.kind === "preview" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    mask: Region {
        item: pageLoader.item?.maskItem ?? pageLoader
    }

    Rectangle {
        id: coverBackground
        anchors.fill: parent
        color: ColorUtils.transparentize(Appearance.m3colors.m3background, Appearance.m3colors.darkmode ? 0.05 : 0.12)
        opacity: root.shownPage.kind === "cover" ? 1 : 0

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    Item {
        id: pageContainer
        anchors.fill: parent
        transform: Translate {
            id: pageShift
        }

        Loader {
            id: pageLoader
            anchors.fill: parent
            sourceComponent: root.shownPage.component
        }
    }

    SequentialAnimation {
        id: pageSwitchAnimation
        NumberAnimation {
            target: pageContainer
            property: "opacity"
            to: 0
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }
        ScriptAction {
            script: root.showPage()
        }
        ParallelAnimation {
            NumberAnimation {
                target: pageContainer
                property: "opacity"
                to: 1
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
            NumberAnimation {
                target: pageShift
                property: "y"
                from: 30
                to: 0
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }
    }

    Process {
        id: clipboardImageHash
        readonly property string emptyHash: "d41d8cd98f00b204e9800998ecf8427e  -"
        property string hash: ""
        command: ["bash", "-c", "wl-paste --no-newline --type image/png 2>/dev/null | md5sum"]
        stdout: StdioCollector {
            onStreamFinished: clipboardImageHash.hash = text.trim()
        }
    }

    SequentialAnimation {
        id: finishAnimation
        NumberAnimation {
            targets: [coverBackground, pageContainer]
            property: "opacity"
            to: 0
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
        ScriptAction {
            script: Onboarding.finish()
        }
    }

    Component {
        id: languagePage
        LanguagePage {
            onNext: root.next()
        }
    }

    Component {
        id: welcomePage
        OnboardingPage {
            icon: "waving_hand"
            title: root.isEonOS ? Translation.tr("Welcome to eonOS!") : Translation.tr("Welcome to illogical-impulse!")
            description: Translation.tr("Let's set things up and learn the basics. It only takes a few minutes.")
            showBack: root.pageIndex > 0
            onNext: root.next()
            onBack: root.back()
        }
    }

    Component {
        id: settingsPage
        SettingsPage {
            onNext: root.next()
            onBack: root.back()
        }
    }

    Component {
        id: askPage
        Item {
            id: askRoot
            readonly property Item maskItem: askRoot

            WindowDialog {
                anchors.fill: parent
                backgroundWidth: 420
                radius: 0
                Component.onCompleted: show = true

                WindowDialogTitle {
                    Layout.fillWidth: true
                    text: Translation.tr("Learn the basics?")
                }
                WindowDialogParagraph {
                    Layout.fillWidth: true
                    text: Translation.tr("Recommended for Hyprland newbies. A series of short interactive lessons will guide you through working with your desktop.")
                }
                WindowDialogButtonRow {
                    Layout.fillWidth: true
                    Item {
                        Layout.fillWidth: true
                    }
                    DialogButton {
                        buttonText: Translation.tr("I'll pass")
                        onClicked: root.goTo(root.pages.length - 1)
                    }
                    DialogButton {
                        buttonText: Translation.tr("Yes, let's start")
                        onClicked: root.next()
                    }
                }
            }
        }
    }

    Component {
        id: tilingPage
        TilingPage {
            onNext: root.next()
            onBack: root.back()
        }
    }

    Component {
        id: appsLesson
        OnboardingLesson {
            icon: "apps"
            title: Translation.tr("Open and close apps")
            description: Translation.tr("You use keyboard shortcuts to open basic apps and they automatically arrange themselves in the layout.")
            tasks: [
                {
                    "text": Translation.tr("Open a terminal"),
                    "keys": ["Super", "Enter"],
                    "check": root.windowOpenedWithClass(/foot|kitty|alacritty|wezterm|konsole|org\.gnome\.console|xterm/i)
                },
                {
                    "text": Translation.tr("Open the file manager"),
                    "keys": ["Super", "E"],
                    "check": root.windowOpenedWithClass(/dolphin|nautilus|nemo|thunar|kitty/i)
                },
                {
                    "text": Translation.tr("Open the text editor"),
                    "keys": ["Super", "X"],
                    "check": root.windowOpenedWithClass(/kate|texteditor|emacs/i)
                },
                {
                    "text": Translation.tr("Close the focused window"),
                    "keys": ["Super", "Q"],
                    "check": root.windowClosed
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: windowsLesson
        OnboardingLesson {
            icon: "open_with"
            title: Translation.tr("Arrange windows")
            description: Translation.tr("The fastest way to move windows is using keybinds. However, you can use the mouse as well!")
            polling: true
            tasks: [
                {
                    "text": Translation.tr("Have at least two windows open"),
                    "keys": ["Super", "Enter"],
                    "check": (base, now) => now.windowsHere >= 2
                },
                {
                    "text": Translation.tr("Focus another window"),
                    "keys": ["Super", "←↑→↓"],
                    "check": (base, now) => now.activeWindow !== base.activeWindow
                },
                {
                    "text": Translation.tr("Move a window"),
                    "keys": ["Super", "Shift", "←↑→↓"],
                    "altKeys": ["Super", "LMB"],
                    "check": (base, now) => root.windowChanged(base, now, "at")
                },
                {
                    "text": Translation.tr("Resize a window"),
                    "keys": ["Super", "; / '"],
                    "altKeys": ["Super", "RMB"],
                    "check": (base, now) => root.windowChanged(base, now, "size")
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: workspacesLesson
        OnboardingLesson {
            icon: "workspaces"
            title: Translation.tr("Switch between workspaces")
            description: Translation.tr("Workspaces are separate desktops, and each one can hold different windows. The shell's bar has a workspace indicator that shows an active workspace.")
            tasks: [
                {
                    "text": Translation.tr("Send the focused window to workspace 2"),
                    "keys": ["Super", "Alt", "2"],
                    "check": (base, now) => root.windowChanged(base, now, "workspace")
                },
                {
                    "text": Translation.tr("Go to workspace 2"),
                    "keys": ["Super", "2"],
                    "check": (base, now) => now.workspace !== base.workspace
                },
                {
                    "text": Translation.tr("Go back to workspace 1"),
                    "keys": ["Super", "1"],
                    "check": (base, now) => now.workspace !== base.workspace
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: scratchpadLesson
        OnboardingLesson {
            icon: "stacks"
            title: Translation.tr("Scratchpad")
            description: Translation.tr("The scratchpad is a hidden workspace that shows up on top of an active one. Hold apps you need across many workspaces and access them with a keybind.")
            tasks: [
                {
                    "text": Translation.tr("Send the focused window to the scratchpad"),
                    "keys": ["Super", "Alt", "S"],
                    "check": (base, now) => root.windowBecame(base, now, "special", true)
                },
                {
                    "text": Translation.tr("Show the scratchpad"),
                    "keys": ["Super", "S"],
                    "check": (base, now) => now.specialShown
                },
                {
                    "text": Translation.tr("Hide it again"),
                    "keys": ["Super", "S"],
                    "check": (base, now) => !now.specialShown
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: floatingLesson
        OnboardingLesson {
            icon: "picture_in_picture"
            title: Translation.tr("Floating windows")
            description: Translation.tr("Floating windows stay above tiled ones and their position and size are independent from the tiling layout. Pinned windows move across workspaces automatically.")
            polling: true
            tasks: [
                {
                    "text": Translation.tr("Make the focused window float"),
                    "keys": ["Super", "Alt", "Space"],
                    "check": (base, now) => root.windowBecame(base, now, "floating", true)
                },
                {
                    "text": Translation.tr("Move it"),
                    "keys": ["Super", "Shift", "←↑→↓"],
                    "altKeys": ["Super", "LMB"],
                    "check": (base, now) => root.windowChanged(base, now, "at")
                },
                {
                    "text": Translation.tr("Pin it"),
                    "keys": ["Super", "P"],
                    "check": (base, now) => root.windowBecame(base, now, "pinned", true)
                },
                {
                    "text": Translation.tr("Switch to another workspace"),
                    "keys": ["Super", "2"],
                    "check": (base, now) => now.workspace !== base.workspace
                },
                {
                    "text": Translation.tr("Unpin it"),
                    "keys": ["Super", "P"],
                    "check": (base, now) => root.windowBecame(base, now, "pinned", false)
                },
                {
                    "text": Translation.tr("Put it back into the tiled layout"),
                    "keys": ["Super", "Alt", "Space"],
                    "check": (base, now) => root.windowBecame(base, now, "floating", false)
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: fullscreenLesson
        OnboardingLesson {
            icon: "fullscreen"
            title: Translation.tr("Maximize and fullscreen")
            description: Translation.tr("Maximized windows take up the whole layout temporarily. Fullscreen windows take up the whole screen.")
            tasks: [
                {
                    "text": Translation.tr("Maximize the focused window"),
                    "keys": ["Super", "D"],
                    "check": (base, now) => root.windowBecame(base, now, "fullscreen", 1)
                },
                {
                    "text": Translation.tr("Restore its size"),
                    "keys": ["Super", "D"],
                    "check": (base, now) => root.windowBecame(base, now, "fullscreen", 0)
                },
                {
                    "text": Translation.tr("Make it fullscreen"),
                    "keys": ["Super", "F"],
                    "check": (base, now) => root.windowBecame(base, now, "fullscreen", 2)
                },
                {
                    "text": Translation.tr("Exit fullscreen"),
                    "keys": ["Super", "F"],
                    "check": (base, now) => root.windowBecame(base, now, "fullscreen", 0)
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: shellLesson
        OnboardingLesson {
            icon: "widgets"
            title: Translation.tr("Shell shortcuts")
            description: Translation.tr("%1 is packed with all sorts of useful utilities and two batteries-included sidebars. Use them as you wish!").arg(root.isEonOS ? "eonOS" : "illogical-impulse")
            tasks: [
                {
                    "text": Translation.tr("Open the left sidebar"),
                    "keys": ["Super", "A"],
                    "check": (base, now) => GlobalStates.sidebarLeftOpen
                },
                {
                    "text": Translation.tr("Open the right sidebar"),
                    "keys": ["Super", "N"],
                    "check": (base, now) => GlobalStates.sidebarRightOpen
                },
                {
                    "text": Translation.tr("Take a screenshot of a region"),
                    "keys": ["Super", "Shift", "S"],
                    "check": (base, now) => {
                        if (GlobalStates.regionSelectorOpen) {
                            base.selectorSeen = true;
                            return false;
                        }
                        clipboardImageHash.running = true;
                        if (!base.selectorSeen) {
                            base.imageHashBefore = clipboardImageHash.hash;
                            return false;
                        }
                        return clipboardImageHash.hash !== base.imageHashBefore && clipboardImageHash.hash !== clipboardImageHash.emptyHash;
                    }
                },
                {
                    "text": Translation.tr("Browse clipboard history"),
                    "keys": ["Super", "V"],
                    "check": (base, now) => root.searchOpenWith(Config.options.search.prefix.clipboard)
                },
                {
                    "text": Translation.tr("Find and copy an emoji"),
                    "keys": ["Super", "."],
                    "check": (base, now) => {
                        if (root.searchOpenWith(Config.options.search.prefix.emojis))
                            base.emojiSearchSeen = true;
                        return base.emojiSearchSeen === true && now.clipboard !== base.clipboard;
                    }
                }
            ]
            onNext: root.next()
        }
    }

    Component {
        id: finishPage
        OnboardingPage {
            icon: "celebration"
            title: Translation.tr("You're all set!")
            description: Translation.tr("You might want to know these shortcuts as well:")
            nextText: Translation.tr("Finish")
            showBack: false
            onNext: finishAnimation.start()

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 2
                rowSpacing: 10
                columnSpacing: 24

                StyledText {
                    text: Translation.tr("Overview and search")
                }
                KeyCombo {
                    keys: ["Super", "Tab"]
                }
                StyledText {
                    text: Translation.tr("Settings")
                }
                KeyCombo {
                    keys: ["Super", "I"]
                }
                StyledText {
                    text: Translation.tr("All keybinds")
                }
                KeyCombo {
                    keys: ["Super", "/"]
                }
                StyledText {
                    text: Translation.tr("Show this guide again")
                }
                KeyCombo {
                    keys: ["Super", "Shift", "Alt", "/"]
                }
            }
        }
    }
}
