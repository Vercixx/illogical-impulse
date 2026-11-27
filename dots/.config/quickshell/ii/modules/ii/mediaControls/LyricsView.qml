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

    readonly property int compactRowHeight: Math.ceil(excerptFont.height)
    implicitHeight: root.compact && root.followsPlayback ? 3 * compactRowHeight + 2 * lyricsList.spacing : 0

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

    ListView {
        id: lyricsList
        anchors.fill: parent
        clip: true
        interactive: !root.compact
        spacing: root.compact ? 2 : 8
        visible: opacity > 0
        opacity: count > 0 ? 1 : 0
        model: {
            if (root.compact && !root.followsPlayback)
                return [];
            if (!root.followsPlayback && root.result?.plain)
                return root.result.plain.split(/\r?\n/);
            const lines = root.syncedLines.map(line => line.text);
            // The empty lead-in keeps the first timed line below center until it starts.
            return root.compact ? [""].concat(lines) : lines;
        }
        currentIndex: root.compact && root.followsPlayback ? root.currentLine + 1 : root.currentLine
        highlight: Item {}
        highlightRangeMode: root.compact ? ListView.StrictlyEnforceRange : ListView.ApplyRange
        preferredHighlightBegin: root.compact ? root.compactRowHeight + spacing : height * 0.42
        preferredHighlightEnd: root.compact ? preferredHighlightBegin + root.compactRowHeight : height * 0.58
        highlightMoveDuration: Appearance.animation.elementResize.duration
        highlightMoveVelocity: -1
        ScrollBar.vertical: ScrollBar {
            policy: root.compact ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
        }

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        delegate: StyledText {
            required property string modelData
            readonly property bool activeLine: root.currentLine >= 0 && ListView.isCurrentItem
            width: root.compact ? lyricsList.width : lyricsList.width - 16
            height: root.compact ? root.compactRowHeight : implicitHeight
            horizontalAlignment: root.compact ? Text.AlignHCenter : undefined
            textFormat: Text.PlainText
            wrapMode: root.compact ? Text.NoWrap : Text.Wrap
            elide: root.compact ? Text.ElideRight : Text.ElideNone
            text: modelData
            color: activeLine && !root.compact ? Appearance.colors.colPrimary : root.lineColor
            font.pixelSize: root.compact ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.large
            font.bold: activeLine
            opacity: !root.followsPlayback || activeLine ? 1 : (root.compact ? 0.65 : 0.7)

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        width: parent.width
        visible: opacity > 0
        opacity: !root.compact && lyricsList.count === 0 ? 1 : 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: root.lineColor

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        text: {
            if (!root.lookupKey || root.result?.status === "unavailable")
                return Translation.tr("Lyrics unavailable");
            if (root.result?.status === "error")
                return Translation.tr("Could not load lyrics");
            return Translation.tr("Loading lyrics…");
        }
    }
}
