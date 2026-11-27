import qs
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

    Component.onCompleted: GlobalStates.mediaDrawers = GlobalStates.mediaDrawers.concat([root])
    Component.onDestruction: GlobalStates.mediaDrawers = GlobalStates.mediaDrawers.filter(drawer => drawer !== root)

    property Component playerComponent: Component {
        PlayerControl {
            player: root.player
            canExpand: true
            onExpandRequested: GlobalStates.mediaFullscreenRequested(root.player, root.barWindow.screen)
            implicitWidth: Appearance.sizes.mediaControlsWidth
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
