import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property var host: null
    property bool alwaysShowAllResources: (host?.shortenLevel ?? 0) === 2
    readonly property color colText: host?.colForeground ?? Appearance.colors.colOnLayer1
    readonly property color colAccent: host?.colAccent ?? Appearance.colors.colOnSecondaryContainer
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    onClicked: resourcesPopup.toggle()

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            colText: root.colText
            colAccent: root.colAccent
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
            colText: root.colText
            colAccent: root.colAccent
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            colText: root.colText
            colAccent: root.colAccent
        }

    }

    ResourcesPopup {
        id: resourcesPopup
        hoverTarget: root
    }
}
