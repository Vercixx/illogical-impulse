import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "folder_managed"
        title: Translation.tr("Dotfiles")

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath("illogical-impulse")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: Translation.tr("illogical-impulse")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/Vercixx/illogical-impulse"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
                StyledText {
                	text: Translation.tr("forked from https://github.com/end-4/dots-hyprland")
                	font.pixelSize: Appearance.font.pixelSize.small
                	textFormat: Text.MarkdownText
                	onLinkActivated: (link) => {
                		Qt.openUrlExternally(link)
                	}
                	HoverHandler {
                		enabled: parent.hoveredLink
                		cursorShape: Qt.PointingHandCursor
                	}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/Vercixx/illogical-impulse/wiki")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/Vercixx/illogical-impulse/issues")
                }
            }
            /* RippleButtonWithIcon {
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/Vercixx/illogical-impulse/discussions")
                }
            } */
            /* RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: Translation.tr("Donate")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/sponsors/end-4")
                }
            } */


        }

        Repeater {
            model: [
                {
                    title: Translation.tr("Borrowed code"),
                    items: [
                        ["caelestia shell", "GPL-3.0", "https://github.com/caelestia-dots/shell"],
                        ["hyprland-material-you", "GPL-3.0", "https://github.com/koeqaife/hyprland-material-you"],
                        ["fuzzysort", "MIT", "https://github.com/farzher/fuzzysort"],
                        ["FastPriorityQueue.js", "Apache-2.0", "https://github.com/lemire/FastPriorityQueue.js"],
                        ["nixnew", Translation.tr("No license, used with the author's permission"), "https://git.outfoxxed.me/outfoxxed/nixnew"],
                        ["thumbnail-generator-ubuntu", "MIT", "https://github.com/difference-engine/thumbnail-generator-ubuntu"],
                        ["kitty-kitten-search", "GPL-3.0", "https://github.com/trygveaa/kitty-kitten-search"],
                        ["Nyarch Assistant", "GPL-3.0", "https://github.com/NyarchLinux/NyarchAssistant"],
                        ["unix.stackexchange.com/a/602935", "CC-BY-SA-4.0", "https://unix.stackexchange.com/a/602935"],
                    ]
                },
                {
                    title: Translation.tr("Desktop"),
                    items: [
                        ["Quickshell", "LGPL-3.0-only", "https://quickshell.org"],
                        ["Hyprland", "BSD-3-Clause", "https://hyprland.org"],
                        ["hypridle", "BSD-3-Clause", "https://github.com/hyprwm/hypridle"],
                        ["hyprlock", "BSD-3-Clause", "https://github.com/hyprwm/hyprlock"],
                        ["hyprpicker", "BSD-3-Clause", "https://github.com/hyprwm/hyprpicker"],
                        ["hyprsunset", "BSD-3-Clause", "https://github.com/hyprwm/hyprsunset"],
                        ["Hyprshot", "GPL-3.0-only", "https://github.com/Gustash/Hyprshot"],
                        ["xdg-desktop-portal", "LGPL-2.1-or-later", "https://github.com/flatpak/xdg-desktop-portal"],
                        ["xdg-desktop-portal-hyprland", "BSD-3-Clause", "https://github.com/hyprwm/xdg-desktop-portal-hyprland"],
                        ["xdg-desktop-portal-gtk", "LGPL-2.1", "https://github.com/flatpak/xdg-desktop-portal-gtk"],
                        ["xdg-desktop-portal-kde", "LGPL-2.0-or-later", "https://invent.kde.org/plasma/xdg-desktop-portal-kde"],
                        ["PipeWire", "MIT, LGPL-2.1-or-later", "https://pipewire.org"],
                        ["WirePlumber", "MIT", "https://gitlab.freedesktop.org/pipewire/wireplumber"],
                        ["NetworkManager", "GPL-2.0-or-later, LGPL-2.1-or-later", "https://networkmanager.dev"],
                        ["UPower", "GPL-2.0-or-later", "https://upower.freedesktop.org"],
                        ["GeoClue", "GPL-2.0-or-later, LGPL-2.1-or-later", "https://gitlab.freedesktop.org/geoclue/geoclue"],
                        ["GNOME Keyring", "GPL-2.0-or-later, LGPL-2.1-or-later", "https://gitlab.gnome.org/GNOME/gnome-keyring"],
                        ["Mesa", "MIT", "https://mesa3d.org"],
                    ]
                },
                {
                    title: Translation.tr("Qt and KDE"),
                    items: [
                        ["Qt", "LGPL-3.0-only, GPL-3.0-only", "https://www.qt.io"],
                        ["Kirigami", "LGPL-2.0-or-later", "https://invent.kde.org/frameworks/kirigami"],
                        ["KSyntaxHighlighting", "MIT", "https://invent.kde.org/frameworks/syntax-highlighting"],
                        ["KDialog", "GPL-2.0-or-later", "https://invent.kde.org/utilities/kdialog"],
                        ["Dolphin", "GPL-2.0-or-later", "https://apps.kde.org/dolphin"],
                        ["System Settings", "GPL-2.0-or-later", "https://invent.kde.org/plasma/systemsettings"],
                        ["BlueDevil", "GPL-2.0-or-later", "https://invent.kde.org/plasma/bluedevil"],
                        ["plasma-nm", "GPL-2.0-or-later", "https://invent.kde.org/plasma/plasma-nm"],
                        ["polkit-kde-agent", "GPL-2.0-or-later", "https://invent.kde.org/plasma/polkit-kde-agent-1"],
                        ["qt-avif-image-plugin", "BSD-2-Clause", "https://github.com/novomesk/qt-avif-image-plugin"],
                        ["kde-material-you-colors", "GPL-3.0", "https://github.com/luisbocanegra/kde-material-you-colors"],
                        ["pavucontrol-qt", "GPL-2.0-or-later", "https://github.com/lxqt/pavucontrol-qt"],
                    ]
                },
                {
                    title: Translation.tr("GTK and GNOME"),
                    items: [
                        ["GTK", "LGPL-2.1-or-later", "https://www.gtk.org"],
                        ["libadwaita", "LGPL-2.1-or-later", "https://gitlab.gnome.org/GNOME/libadwaita"],
                        ["GLib", "LGPL-2.1-or-later", "https://gitlab.gnome.org/GNOME/glib"],
                        ["libsoup", "LGPL-2.0-or-later", "https://gitlab.gnome.org/GNOME/libsoup"],
                        ["libportal", "LGPL-3.0", "https://github.com/flatpak/libportal"],
                        ["GObject Introspection", "LGPL-2.0-or-later, GPL-2.0-or-later", "https://gitlab.gnome.org/GNOME/gobject-introspection"],
                        ["libdbusmenu", "LGPL-2.1-only OR LGPL-3.0-only", "https://launchpad.net/libdbusmenu"],
                        ["gtkmm", "LGPL-2.1-or-later", "https://www.gtkmm.org"],
                        ["cairomm", "LGPL-2.0-or-later", "https://www.cairographics.org/cairomm/"],
                        ["gtksourceviewmm", "LGPL-2.1-or-later", "https://gitlab.gnome.org/GNOME/gtksourceviewmm"],
                    ]
                },
                {
                    title: Translation.tr("Utilities"),
                    items: [
                        ["MicroTeX", "MIT", "https://github.com/NanoMichael/MicroTeX"],
                        ["matugen", "GPL-2.0", "https://github.com/InioX/matugen"],
                        ["cava", "MIT", "https://github.com/karlstav/cava"],
                        ["playerctl", "LGPL-3.0-only", "https://github.com/altdesktop/playerctl"],
                        ["brightnessctl", "MIT", "https://github.com/Hummer12007/brightnessctl"],
                        ["ddcutil", "GPL-2.0-or-later", "https://www.ddcutil.com"],
                        ["cliphist", "GPL-3.0", "https://github.com/sentriz/cliphist"],
                        ["wl-clipboard", "GPL-3.0-or-later", "https://github.com/bugaevc/wl-clipboard"],
                        ["fuzzel", "MIT", "https://codeberg.org/dnkl/fuzzel"],
                        ["wlogout", "MIT", "https://github.com/ArtsyMacaw/wlogout"],
                        ["slurp", "MIT", "https://github.com/emersion/slurp"],
                        ["swappy", "MIT", "https://github.com/jtheoof/swappy"],
                        ["Tesseract", "Apache-2.0", "https://github.com/tesseract-ocr/tesseract"],
                        ["wf-recorder", "MIT", "https://github.com/ammen99/wf-recorder"],
                        ["ImageMagick", "ImageMagick", "https://imagemagick.org"],
                        ["SongRec", "GPL-3.0-only", "https://github.com/marin-m/SongRec"],
                        ["Translate Shell", "Unlicense", "https://github.com/soimort/translate-shell"],
                        ["Qalculate!", "GPL-2.0", "https://qalculate.github.io"],
                        ["wtype", "MIT", "https://github.com/atx/wtype"],
                        ["ydotool", "AGPL-3.0-or-later", "https://github.com/ReimuNotMoe/ydotool"],
                        ["kitty", "GPL-3.0-only", "https://sw.kovidgoyal.net/kitty"],
                        ["fish", "GPL-2.0-only", "https://fishshell.com"],
                        ["Starship", "ISC", "https://starship.rs"],
                        ["eza", "EUPL-1.2", "https://github.com/eza-community/eza"],
                        ["jq", "MIT", "https://jqlang.org"],
                        ["yq", "MIT", "https://github.com/mikefarah/yq"],
                        ["ripgrep", "MIT OR Unlicense", "https://github.com/BurntSushi/ripgrep"],
                        ["curl", "curl", "https://curl.se"],
                        ["Wget", "GPL-3.0-or-later", "https://www.gnu.org/software/wget"],
                        ["rsync", "GPL-3.0-or-later", "https://rsync.samba.org"],
                        ["bc", "GPL-3.0-only", "https://www.gnu.org/software/bc"],
                        ["GNU Coreutils", "GPL-3.0-or-later", "https://www.gnu.org/software/coreutils"],
                        ["xdg-user-dirs", "GPL-2.0-or-later", "https://gitlab.freedesktop.org/xdg/xdg-user-dirs"],
                        ["Fontconfig", "HPND", "https://gitlab.freedesktop.org/fontconfig/fontconfig"],
                        ["uv", "MIT OR Apache-2.0", "https://github.com/astral-sh/uv"],
                        ["CMake", "BSD-3-Clause", "https://cmake.org"],
                        ["Clang", "Apache-2.0 WITH LLVM-exception", "https://clang.llvm.org"],
                        ["cpptrace", "MIT", "https://github.com/jeremy-rifkin/cpptrace"],
                        ["jemalloc", "BSD-2-Clause", "https://github.com/jemalloc/jemalloc"],
                        ["TinyXML-2", "Zlib", "https://github.com/leethomason/tinyxml2"],
                    ]
                },
                {
                    title: Translation.tr("Python libraries"),
                    items: [
                        ["materialyoucolor", "MIT", "https://github.com/T-Dynamos/materialyoucolor-python"],
                        ["material-color-utilities", "Apache-2.0", "https://github.com/material-foundation/material-color-utilities"],
                        ["Pillow", "MIT-CMU", "https://github.com/python-pillow/Pillow"],
                        ["NumPy", "BSD-3-Clause", "https://numpy.org"],
                        ["OpenCV", "Apache-2.0", "https://opencv.org"],
                        ["PyGObject", "LGPL-2.1-or-later", "https://pygobject.gnome.org"],
                        ["pycairo", "LGPL-2.1-only OR MPL-1.1", "https://github.com/pygobject/pycairo"],
                        ["pywayland", "Apache-2.0", "https://github.com/flacjacket/pywayland"],
                        ["psutil", "BSD-3-Clause", "https://github.com/giampaolo/psutil"],
                        ["libsass-python", "MIT", "https://github.com/sass/libsass-python"],
                        ["setproctitle", "BSD-3-Clause", "https://github.com/dvarrazzo/py-setproctitle"],
                        ["Click", "BSD-3-Clause", "https://github.com/pallets/click"],
                        ["Loguru", "MIT", "https://github.com/Delgan/loguru"],
                        ["tqdm", "MPL-2.0 AND MIT", "https://github.com/tqdm/tqdm"],
                        ["google-auth", "Apache-2.0", "https://github.com/googleapis/google-auth-library-python"],
                        ["Requests", "Apache-2.0", "https://github.com/psf/requests"],
                        ["build", "MIT", "https://github.com/pypa/build"],
                        ["setuptools-scm", "MIT", "https://github.com/pypa/setuptools-scm"],
                        ["wheel", "MIT", "https://github.com/pypa/wheel"],
                    ]
                },
                {
                    title: Translation.tr("Fonts and themes"),
                    items: [
                        ["Space Grotesk", "OFL-1.1", "https://github.com/floriankarsten/space-grotesk"],
                        ["Rubik", "OFL-1.1", "https://github.com/googlefonts/rubik"],
                        ["Readex Pro", "OFL-1.1", "https://github.com/ThomasJockin/readexpro"],
                        ["JetBrains Mono", "OFL-1.1", "https://github.com/JetBrains/JetBrainsMono"],
                        ["Nerd Fonts", "OFL-1.1, MIT", "https://www.nerdfonts.com"],
                        ["Material Symbols", "Apache-2.0", "https://github.com/google/material-design-icons"],
                        ["Twemoji", "MIT, CC-BY-4.0", "https://github.com/jdecked/twemoji"],
                        ["adw-gtk3", "LGPL-2.1", "https://github.com/lassekongo83/adw-gtk3"],
                        ["Breeze", "GPL-2.0-or-later", "https://invent.kde.org/plasma/breeze"],
                        ["Breeze Plus", "LGPL-2.1", "https://github.com/mjkim0727/breeze-plus"],
                        ["Darkly", "GPL-2.0-or-later", "https://github.com/Bali10050/Darkly"],
                        ["Bibata Cursor", "GPL-3.0", "https://github.com/ful1e5/Bibata_Cursor"],
                    ]
                },
            ]

            ContentSubsection {
                id: creditGroup
                required property var modelData
                title: modelData.title

                Repeater {
                    model: creditGroup.modelData.items

                    RippleButton {
                        id: creditRow
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: creditText.implicitHeight + 8 * 2
                        horizontalPadding: 12
                        buttonRadius: Appearance.rounding.normal
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: Qt.openUrlExternally(modelData[2])

                        contentItem: ColumnLayout {
                            id: creditText
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: creditRow.modelData[0]
                            }
                            StyledText {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: creditRow.modelData[1]
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }
    }
}
