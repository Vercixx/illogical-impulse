import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item { // Bar content region
    id: root

    readonly property var traits: Appearance.barStyle
    readonly property bool vertical: Config.options.bar.vertical
    property var screen: root.QsWindow.window?.screen
    readonly property int shortenLevel: vertical ? 0 : (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property bool workspacesOnly: !Onboarding.shows("bar")
    readonly property real margin: traits.floating ? Appearance.sizes.hyprlandGapsOut : 0
    readonly property real sectionInset: traits.sections === "round" ? margin : 0
    readonly property real sectionGap: 4

    Loader {
        active: root.traits.strip && root.traits.floating
        anchors.fill: strip
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: strip
        }
    }
    Rectangle {
        id: strip
        visible: root.traits.strip
        anchors {
            fill: parent
            margins: root.margin
        }
        color: Appearance.colors.colLayer0Base
        radius: root.traits.floating ? Appearance.rounding.windowRounding : 0
        border.width: root.traits.floating ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    FocusedScrollMouseArea { // Start side | scroll to change brightness
        id: startArea
        anchors {
            left: parent.left
            top: parent.top
            right: root.vertical ? parent.right : centerSection.left
            bottom: root.vertical ? centerSection.top : parent.bottom
        }

        onScrollDown: if (!root.workspacesOnly) Brightness.decreaseBrightness()
        onScrollUp: if (!root.workspacesOnly) Brightness.increaseBrightness()
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (root.workspacesOnly || event.button !== Qt.LeftButton)
                return;
            GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        ScrollHint {
            reveal: startArea.hovered && !root.vertical && !root.workspacesOnly
            icon: Hyprsunset.gamma === 100 ? "light_mode" : "wb_twilight"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSection {
            edge: "start"
            groups: Config.options.bar.layout.left
            bar: root
            sideHovered: startArea.hovered
            maximumLength: (root.vertical ? startArea.height : startArea.width) - root.sectionInset - root.sectionGap
            x: root.vertical ? (parent.width - width) / 2 : root.sectionInset
            y: root.vertical ? root.sectionInset : (parent.height - height) / 2
        }
    }

    BarSection {
        id: centerSection
        edge: "center"
        groups: Config.options.bar.layout.center
        bar: root
        maximumLength: root.vertical ? root.height : root.width
        anchors.centerIn: parent
    }

    FocusedScrollMouseArea { // End side | scroll to change volume
        id: endArea
        anchors {
            left: root.vertical ? parent.left : centerSection.right
            top: root.vertical ? centerSection.bottom : parent.top
            right: parent.right
            bottom: parent.bottom
        }

        onScrollDown: if (!root.workspacesOnly) Audio.decrementVolume()
        onScrollUp: if (!root.workspacesOnly) Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (root.workspacesOnly || event.button !== Qt.LeftButton)
                return;
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        ScrollHint {
            reveal: endArea.hovered && !root.vertical && !root.workspacesOnly
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSection {
            edge: "end"
            groups: Config.options.bar.layout.right
            bar: root
            sideHovered: endArea.hovered
            maximumLength: (root.vertical ? endArea.height : endArea.width) - root.sectionInset - root.sectionGap
            x: root.vertical ? (parent.width - width) / 2 : parent.width - width - root.sectionInset
            y: root.vertical ? parent.height - height - root.sectionInset : (parent.height - height) / 2
        }
    }
}
