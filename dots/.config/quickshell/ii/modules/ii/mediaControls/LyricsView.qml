pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "../../../services/Lrc.js" as Lrc

Item {
    id: root
    required property MprisPlayer player
    property bool compact: false
    property color lineColor: Appearance.colors.colOnLayer0

    readonly property string lookupKey: Lyrics.trackQuery(root.player)
    readonly property var result: Lyrics.results[root.lookupKey]
    readonly property var syncedLines: root.result?.lines ?? []
    readonly property bool followsPlayback: (root.player?.positionSupported ?? false) && root.syncedLines.length > 0
    readonly property int currentLine: root.followsPlayback ? Lrc.activeLine(root.syncedLines, root.player.position) : -1
    property string subscribedKey: ""

    implicitHeight: root.compact && root.followsPlayback ? 3 * Math.ceil(excerptFont.height) + 2 * excerpt.spacing : 0

    function subscribe() {
        if (root.subscribedKey === root.lookupKey)
            return;
        if (root.subscribedKey)
            Lyrics.release(root.subscribedKey);
        root.subscribedKey = root.lookupKey;
        if (root.subscribedKey)
            Lyrics.retain(root.subscribedKey);
    }

    onLookupKeyChanged: root.subscribe()
    Component.onCompleted: root.subscribe()
    Component.onDestruction: {
        if (root.subscribedKey)
            Lyrics.release(root.subscribedKey);
    }

    FontMetrics {
        id: excerptFont
        font.family: Appearance.font.family.main
        font.pixelSize: Appearance.font.pixelSize.small
    }

    Column {
        id: excerpt
        width: root.width
        spacing: 2
        visible: root.compact && root.followsPlayback

        Repeater {
            model: root.compact && root.followsPlayback ? 3 : 0
            delegate: StyledText {
                required property int index
                width: excerpt.width
                height: Math.ceil(excerptFont.height)
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: root.lineColor
                opacity: index === 1 ? 1 : 0.65
                font.pixelSize: Appearance.font.pixelSize.small
                font.bold: index === 1
                text: root.syncedLines[root.currentLine + index - 1]?.text ?? ""
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: !root.compact
        sourceComponent: Item {
            ListView {
                id: lyricsList
                anchors.fill: parent
                clip: true
                spacing: 8
                visible: count > 0
                model: !root.followsPlayback && root.result?.plain
                    ? root.result.plain.split(/\r?\n/)
                    : root.syncedLines.map(line => line.text)
                currentIndex: root.currentLine
                ScrollBar.vertical: ScrollBar {}

                function followLine() {
                    if (lyricsList.currentIndex >= 0)
                        lyricsList.positionViewAtIndex(lyricsList.currentIndex, ListView.Center);
                    else
                        lyricsList.positionViewAtBeginning();
                }

                onCurrentIndexChanged: Qt.callLater(lyricsList.followLine)
                onCountChanged: Qt.callLater(lyricsList.followLine)

                delegate: StyledText {
                    required property int index
                    required property string modelData
                    width: lyricsList.width - 16
                    text: modelData
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: index === root.currentLine
                    color: index === root.currentLine ? Appearance.colors.colPrimary : root.lineColor
                    opacity: !root.followsPlayback || index === root.currentLine ? 1 : 0.7
                }
            }

            StyledText {
                anchors.centerIn: parent
                width: parent.width
                visible: !lyricsList.visible
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: root.lineColor
                text: {
                    if (!root.lookupKey || root.result?.status === "unavailable")
                        return Translation.tr("Lyrics unavailable");
                    if (root.result?.status === "error")
                        return Translation.tr("Could not load lyrics");
                    return Translation.tr("Loading lyrics…");
                }
            }
        }
    }
}
