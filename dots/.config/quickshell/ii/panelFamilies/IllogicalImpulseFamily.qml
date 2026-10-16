import QtQuick
import Quickshell

import qs.modules.common
import qs.services
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.cheatsheet
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector

Scope {
    readonly property bool barShown: Onboarding.shows("bar") || Onboarding.shows("workspaces")

    PanelLoader { extraCondition: !Config.options.bar.vertical && barShown; component: Bar {} }
    PanelLoader { component: Background {} }
    PanelLoader { extraCondition: !Onboarding.active; component: Cheatsheet {} }
    PanelLoader { extraCondition: Config.options.dock.enable && Onboarding.shows("dock"); component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { extraCondition: !Onboarding.active; component: MediaControls {} }
    PanelLoader { extraCondition: !Onboarding.active; component: NotificationPopup {} }
    PanelLoader { extraCondition: !Onboarding.active; component: OnScreenDisplay {} }
    PanelLoader { extraCondition: !Onboarding.active; component: OnScreenKeyboard {} }
    PanelLoader { extraCondition: !Onboarding.active; component: Overlay {} }
    PanelLoader { extraCondition: Onboarding.shows("overview"); component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { extraCondition: Onboarding.shows("screenshot"); component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { extraCondition: !Onboarding.active; component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { extraCondition: Onboarding.shows("sidebars"); component: SidebarLeft {} }
    PanelLoader { extraCondition: Onboarding.shows("sidebars"); component: SidebarRight {} }
    PanelLoader { extraCondition: Config.options.bar.vertical && barShown; component: VerticalBar {} }
    PanelLoader { extraCondition: !Onboarding.active; component: WallpaperSelector {} }
}
