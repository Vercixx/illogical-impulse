import QtQuick
import QtQuick.Layouts
import qs.services

OnboardingPage {
    icon: "dashboard"
    title: Translation.tr("Windows that arrange themselves")
    description: Translation.tr("Hyprland, which powers this desktop, is a tiling window manager. Instead of piling on top of each other, windows split the free space on screen, so everything is visible. Most of the actions are done using keybinds, usually with the Super key (one with Windows logo)")

    LayoutDemo {
        Layout.alignment: Qt.AlignHCenter
    }
}
