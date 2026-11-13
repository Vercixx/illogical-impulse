pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string query: ""
    readonly property var queryTokens: query.toLowerCase().split(/[\s+]+/).filter(token => token.length > 0)
    readonly property var firstShownCategory: categories.find(category => category.rows.some(row => root.matches(row))) ?? null
    readonly property bool hasMatches: firstShownCategory !== null

    // Excellent symbol explaination and source :
    // http://xahlee.info/comp/unicode_computing_symbols.html
    // https://www.nerdfonts.com/cheat-sheet
    property var macSymbolMap: ({
        "Ctrl": "󰘴",
        "Alt": "󰘵",
        "Shift": "󰘶",
        "Space": "󱁐",
        "Tab": "↹",
        "Equal": "󰇼",
        "Minus": "",
        "Print": "",
        "BackSpace": "󰭜",
        "Delete": "⌦",
        "Return": "󰌑",
        "Period": ".",
        "Escape": "⎋"
      })
    property var functionSymbolMap: ({
        "F1":  "󱊫",
        "F2":  "󱊬",
        "F3":  "󱊭",
        "F4":  "󱊮",
        "F5":  "󱊯",
        "F6":  "󱊰",
        "F7":  "󱊱",
        "F8":  "󱊲",
        "F9":  "󱊳",
        "F10": "󱊴",
        "F11": "󱊵",
        "F12": "󱊶",
    })

    property var mouseSymbolMap: ({
        "mouse_up": "󱕐",
        "mouse_down": "󱕑",
        "mouse:272": "L󰍽",
        "mouse:273": "R󰍽",
        "Scroll ↑/↓": "󱕒",
        "Page_↑/↓": "⇞/⇟",
    })

    property var keyBlacklist: ["SUPER_L", "SUPER_R"]
    property var keySubstitutions: Object.assign({
        "Super": "",
        "mouse_up": "Scroll ↓",    // ikr, weird
        "mouse_down": "Scroll ↑",  // trust me bro
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:274": "MMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Semicolon": ";",
        "Apostrophe": "'",
        "BracketLeft": "[",
        "BracketRight": "]",
        "Hash": "#",
        "Return": "Enter",
        "Left": "←",
        "Right": "→",
        "Up": "↑",
        "Down": "↓",
        "Page_Up": "PgUp",
        "Page_Down": "PgDn",
        // "Shift": "",
      },
      !!Config.options.cheatsheet.superKey ? {
          "Super": Config.options.cheatsheet.superKey,
      }: {},
      Config.options.cheatsheet.useMacSymbol ? macSymbolMap : {},
      Config.options.cheatsheet.useFnSymbol ? functionSymbolMap : {},
      Config.options.cheatsheet.useMouseSymbol ? mouseSymbolMap : {},
    )

    function modMaskToStringList(modMask: int): list<string> {
        var list = [];
        // Funny mathematical order but we wanna have this natural user-facing order
        if (modMask & (1 << 2)) { list.push("Ctrl"); }
        if (modMask & (1 << 6)) { list.push("Super"); }
        if (modMask & (1 << 0)) { list.push("Shift"); }
        if (modMask & (1 << 3)) { list.push("Alt"); }
        if (modMask & (1 << 1)) { list.push("Caps"); }
        if (modMask & (1 << 4)) { list.push("Mod2"); }
        if (modMask & (1 << 5)) { list.push("Mod3"); }
        if (modMask & (1 << 7)) { list.push("Mod5"); }
        return list;
    }

    // A row lists every function bound to its first combo, then every other combo with those functions
    readonly property var categories: {
        const entries = [];
        for (const bind of HyprlandKeybinds.keybinds) {
            if (!bind.description) continue;
            const id = `${bind.description}|${bind.modmask}|${bind.submap}|${bind.mouse}`;
            let entry = entries.find(entry => entry.id === id);
            if (!entry) {
                entry = { id: id, description: bind.description, modmask: bind.modmask, submap: bind.submap, keys: [] };
                entries.push(entry);
            }
            if (!root.keyBlacklist.includes(bind.key) && !entry.keys.includes(bind.key))
                entry.keys.push(bind.key);
        }

        const slots = [];
        for (const entry of entries) {
            const combo = entry.keys.length > 0 ? `${entry.modmask}|${entry.submap}|${entry.keys.slice().sort().join(" ")}` : entry.id;
            let slot = slots.find(slot => slot.combo === combo);
            if (!slot) {
                slot = { combo: combo, modmask: entry.modmask, keys: entry.keys, descriptions: [] };
                slots.push(slot);
            }
            slot.descriptions.push(entry.description);
        }

        const groups = [];
        for (const slot of slots) {
            const separator = slot.descriptions[0].indexOf(":");
            const name = separator > 0 ? slot.descriptions[0].substring(0, separator).trim() : "";
            let group = groups.find(group => group.name === name);
            if (!group) {
                group = { name: name, rows: [] };
                groups.push(group);
            }
            const id = slot.descriptions.join("|");
            let row = group.rows.find(row => row.id === id);
            if (!row) {
                row = { id: id, descriptions: slot.descriptions, combos: [] };
                group.rows.push(row);
            }
            row.combos.push({ modmask: slot.modmask, keys: slot.keys });
        }
        return groups.filter(group => group.name).concat(groups.filter(group => !group.name));
    }

    function keyLabel(key) {
        return root.keySubstitutions[key] || key;
    }

    // Translations keep the "Category: " prefix, so keys can't collide with other UI strings
    function translatedParts(description) {
        const text = Translation.tr(description);
        const separator = text.indexOf(":");
        if (separator < 0) return { category: "", action: text };
        return { category: text.substring(0, separator).trim(), action: text.substring(separator + 1).trim() };
    }

    function categoryTitle(category) {
        if (!category.name) return Translation.tr("Other");
        const translated = category.rows.map(row => root.translatedParts(row.descriptions[0]).category).find(name => name && name !== category.name);
        return translated ?? category.name;
    }

    function comboParts(combo) {
        const mods = root.modMaskToStringList(combo.modmask).map(mod => root.keyLabel(mod));
        const keys = combo.keys.map(key => root.keyLabel(key));
        const parts = Config.options.cheatsheet.splitButtons || mods.length === 0 ? mods : [mods.join(" ")];
        if (keys.length > 0) parts.push(keys.length > 4 ? `${keys[0]}…${keys[keys.length - 1]}` : keys.join("/"));
        return parts;
    }

    function matches(row) {
        if (root.queryTokens.length === 0) return true;
        const texts = row.descriptions.map(description => `${Translation.tr(description)} ${description}`);
        const combos = row.combos.map(combo => [...root.modMaskToStringList(combo.modmask), ...combo.keys, ...root.comboParts(combo)].join(" "));
        const haystack = texts.concat(combos).join(" ").toLowerCase();
        return root.queryTokens.every(token => haystack.includes(token));
    }

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        ColumnLayout {
            id: contentColumn
            width: flickable.width
            spacing: 0

            Repeater {
                model: root.categories
                delegate: CategorySection {}
            }
        }
    }

    PagePlaceholder {
        shown: !root.hasMatches
        icon: "search_off"
        title: Translation.tr("No matching keybinds")
    }

    component CategorySection: ColumnLayout {
        id: section
        required property var modelData
        readonly property var shownIds: modelData.rows.filter(row => root.matches(row)).map(row => row.id)

        Layout.fillWidth: true
        visible: sectionHeader.implicitHeight > 0
        spacing: 0

        Collapsible {
            id: sectionHeader
            shown: section.shownIds.length > 0
            implicitContentHeight: headerText.implicitHeight + headerText.anchors.topMargin + 8

            StyledText {
                id: headerText
                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: section.modelData.name === root.firstShownCategory?.name ? 4 : 20
                    leftMargin: 4
                }
                text: root.categoryTitle(section.modelData)
                color: Appearance.colors.colPrimary

                Behavior on anchors.topMargin {
                    animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                }
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
            }
        }

        Repeater {
            model: section.modelData.rows
            delegate: Collapsible {
                id: keybindRow
                required property var modelData
                readonly property bool first: section.shownIds[0] === modelData.id
                readonly property bool last: section.shownIds[section.shownIds.length - 1] === modelData.id
                shown: section.shownIds.includes(modelData.id)
                implicitContentHeight: rowBackground.implicitHeight + 2

                Rectangle {
                    id: rowBackground
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    implicitHeight: Math.max(48, rowLayout.implicitHeight + 16)
                    color: Appearance.m3colors.m3surfaceContainerLow
                    topLeftRadius: keybindRow.first ? Appearance.rounding.small : Appearance.rounding.verysmall
                    topRightRadius: topLeftRadius
                    bottomLeftRadius: keybindRow.last ? Appearance.rounding.small : Appearance.rounding.verysmall
                    bottomRightRadius: bottomLeftRadius

                    Behavior on topLeftRadius {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                    }
                    Behavior on bottomLeftRadius {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                    }

                    RowLayout {
                        id: rowLayout
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 16
                            rightMargin: 12
                        }
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Repeater {
                                model: keybindRow.modelData.descriptions
                                delegate: RowLayout {
                                    id: actionLine
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 6

                                    OrLabel {
                                        visible: actionLine.index > 0
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        color: Appearance.colors.colOnLayer1
                                        font.pixelSize: Config.options.cheatsheet.fontSize.comment || Appearance.font.pixelSize.small
                                        text: root.translatedParts(actionLine.modelData).action
                                    }
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: 4

                            Repeater {
                                model: keybindRow.modelData.combos
                                delegate: RowLayout {
                                    id: comboLine
                                    required property var modelData
                                    required property int index
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 3

                                    OrLabel {
                                        visible: comboLine.index > 0
                                        Layout.rightMargin: 3
                                    }
                                    Repeater {
                                        model: root.comboParts(comboLine.modelData)
                                        delegate: RowLayout {
                                            id: keyPart
                                            required property string modelData
                                            required property int index
                                            spacing: 3

                                            StyledText {
                                                visible: keyPart.index > 0
                                                text: "+"
                                            }
                                            KeyboardKey {
                                                key: keyPart.modelData
                                                pixelSize: Config.options.cheatsheet.fontSize.key
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component OrLabel: StyledText {
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.smaller
        text: Translation.tr("or")
    }

    component Collapsible: Item {
        property bool shown: true
        property real implicitContentHeight: 0

        Layout.fillWidth: true
        implicitHeight: shown ? implicitContentHeight : 0
        opacity: shown ? 1 : 0
        visible: implicitHeight > 0
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}