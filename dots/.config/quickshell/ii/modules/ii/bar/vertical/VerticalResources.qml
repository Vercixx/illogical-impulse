import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property var host: null
    readonly property color colAccent: host?.colAccent ?? Appearance.colors.colOnSecondaryContainer
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    onClicked: resourcesPopup.toggle()

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.fill: parent

        VerticalResource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            colAccent: root.colAccent
        }

        VerticalResource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
            colAccent: root.colAccent
        }

        VerticalResource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            colAccent: root.colAccent
        }

    }

    Bar.ResourcesPopup {
        id: resourcesPopup
        hoverTarget: root
    }
}
