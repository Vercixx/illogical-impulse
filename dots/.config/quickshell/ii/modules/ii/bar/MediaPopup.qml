import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.mediaControls
import qs.services
import QtQuick
import Quickshell.Services.Mpris

BarDrawer {
    id: root
    readonly property MprisPlayer player: MprisController.activePlayer

    infoWhenPinned: controls === null
    controls: player ? playerComponent : null

    property Component playerComponent: Component {
        PlayerControl {
            player: root.player
            implicitWidth: Appearance.sizes.mediaControlsWidth
            implicitHeight: Appearance.sizes.mediaControlsHeight
            radius: Appearance.rounding.normal
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        StyledPopupHeaderRow {
            icon: "music_note"
            label: Translation.tr("Media")
        }

        StyledText {
            color: Appearance.colors.colOnSurfaceVariant
            text: `${StringUtils.cleanMusicTitle(root.player?.trackTitle) || Translation.tr("No media")}${root.player?.trackArtist ? '\n' + root.player.trackArtist : ''}`
        }
    }
}
