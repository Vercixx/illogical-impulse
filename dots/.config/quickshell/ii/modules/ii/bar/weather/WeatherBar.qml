pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property var host: null
    readonly property bool vertical: Config.options.bar.vertical
    readonly property color colForeground: host?.colForeground ?? Appearance.colors.colOnLayer1
    property bool hovered: false
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : rowLayout.implicitWidth
    implicitHeight: vertical ? rowLayout.implicitHeight : Appearance.sizes.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onPressed: {
        if (mouse.button === Qt.LeftButton) {
            weatherPopup.toggle();
        } else if (mouse.button === Qt.RightButton) {
            Weather.getData();
            Quickshell.execDetached(["notify-send", 
                Translation.tr("Weather"), 
                Translation.tr("Refreshing (manually triggered)")
                , "-a", "Shell"
            ])
            mouse.accepted = false
        }
    }

    BoxLayout {
        id: rowLayout
        vertical: root.vertical
        spacing: root.vertical ? 0 : 5
        anchors.centerIn: parent

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: root.colForeground
            Layout.alignment: Qt.AlignCenter
        }

        StyledText {
            font.pixelSize: root.vertical ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
            color: root.colForeground
            text: Weather.data?.temp ?? "--°"
            Layout.alignment: Qt.AlignCenter
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}
