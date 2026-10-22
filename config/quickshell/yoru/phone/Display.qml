import QtQuick
import qs
import qs.parts
import "actions.js" as Actions

// the phone's screen: its background, the status bar, the pages side by side and the way
// between them, and the Wi-Fi and Bluetooth panels that slide over the control page.
// `look` comes from the body: slab (a status bar round a little island, page pills, a home
// bar), keitai (signal, time and battery as on a flip phone, soft-key labels along the
// bottom) or bare. Phone.qml hands it every key
Item {
    id: d
    required property var phone
    property string look: "slab"
    property real power: 1                  // the screen lighting up as the phone opens, 0..1
    readonly property bool compact: height < 560
    readonly property var pages: phone.pages
    readonly property int index: Math.max(0, pages.indexOf(phone.page))
    readonly property Item current: deck.currentItem?.item ?? null
    readonly property Item panelItem: panelView.item

    // keys come here when no field has them, and whatever a field leaves
    focus: true
    Keys.onPressed: e => { if (d.key(e)) e.accepted = true; }

    function page(name) {
        const i = pages.indexOf(name);
        const slot = i >= 0 ? deck.itemAtIndex(i) : null;
        return slot ? slot.item : null;
    }
    // one page either way, round the ends
    function step(dir) {
        if (phone.panel !== "") return;
        const n = pages.length;
        phone.page = pages[(index + dir + n) % n];
    }
    // backs out of a panel, then a search; false when there's nothing left but closing
    function back() {
        if (phone.panel !== "") { phone.panel = ""; return true; }
        const h = page("home");
        if (h && h.query !== "") { h.clear(); return true; }
        return false;
    }
    // a key pressed on the flip's keypad, as if it had been typed
    function press(code) { key({ key: code, text: "", modifiers: Qt.NoModifier }); }

    // the flip's keys move as their keyboard keys are pressed
    function keyName(e) {
        switch (e.key) {
        case Qt.Key_Up: return "up";
        case Qt.Key_Down: return "down";
        case Qt.Key_Left: return "left";
        case Qt.Key_Right: return "right";
        case Qt.Key_Return: case Qt.Key_Enter: return "ok";
        case Qt.Key_Escape: return "end";
        }
        return "";
    }
    // 1–9, *, 0 and # on the flip are its shortcuts, while nothing's being searched
    function keypad(text) {
        if (look !== "keitai" || !/^[0-9*#]$/.test(text)) return false;
        const h = page("home");
        if (h && h.query !== "") return false;
        phone.keypad(text);
        return true;
    }

    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        const k = e.key;
        const name = keyName(e);
        if (name !== "") phone.keyed(name);
        if (k === Qt.Key_Escape) {
            if (!back()) phone.close();
            return true;
        }
        if (k === Qt.Key_Tab || (ctrl && k === Qt.Key_PageDown)) { step(1); return true; }
        if (k === Qt.Key_Backtab || (ctrl && k === Qt.Key_PageUp)) { step(-1); return true; }
        const t = phone.panel !== "" ? panelItem : current;
        if (t && typeof t.key === "function" && t.key(e)) return true;
        if (phone.panel !== "") return false;
        if (k === Qt.Key_Left || k === Qt.Key_Right) { step(k === Qt.Key_Left ? -1 : 1); return true; }
        // typing searches your apps, from any page (letters and the like: not Backspace, not a space)
        const c = e.text.length === 1 ? e.text.charCodeAt(0) : 0;
        if (c > 32 && c !== 127 && !ctrl && !(e.modifiers & Qt.AltModifier)) {
            if (keypad(e.text)) return true;
            page("home")?.typeIn(e.text);
            return true;
        }
        return false;
    }

    Backdrop { anchors.fill: parent; kind: d.phone.c.screen }

    StatusBar {
        id: bar
        width: parent.width
        phone: d.phone
        look: d.look
        compact: d.compact
    }

    ListView {
        id: deck
        anchors { left: parent.left; right: parent.right; top: bar.bottom; bottom: foot.top }
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: Theme.normal
        highlightMoveVelocity: -1
        boundsBehavior: Flickable.StopAtBounds
        // every page stays made: swiping back shouldn't build one again
        cacheBuffer: Math.max(1, width * d.pages.length)
        clip: true
        interactive: d.phone.panel === ""
        model: d.pages
        // it follows the phone's page; only a swipe sets the page (a list changed under it
        // resets it to the first, which mustn't count as going there)
        function follow(jump) {
            if (currentIndex !== d.index) currentIndex = d.index;
            if (jump) positionViewAtIndex(d.index, ListView.Beginning);
        }
        Connections {
            target: d
            function onIndexChanged() { deck.follow(false); }
        }
        Component.onCompleted: follow(true)
        onCountChanged: Qt.callLater(() => deck.follow(true))
        onCurrentIndexChanged: {
            if (!moving && !dragging) return;
            const p = d.pages[currentIndex];
            if (p && p !== d.phone.page) d.phone.page = p;
        }
        delegate: Loader {
            id: slot
            required property string modelData
            required property int index
            width: deck.width
            height: deck.height
            readonly property bool live: d.phone.shown && deck.currentIndex === index && d.phone.panel === ""
            // the page it opens on is made at once; the others while it's on its way in
            asynchronous: index !== d.index
            sourceComponent: ({ home: homeC, control: controlC, today: todayC, music: musicC })[modelData] ?? null
            onLoaded: item.live = Qt.binding(() => slot.live)
        }
    }
    Component { id: homeC; HomePage { phone: d.phone; compact: d.compact; display: d } }
    Component { id: controlC; ControlPage { phone: d.phone; compact: d.compact } }
    Component { id: todayC; TodayPage { phone: d.phone; compact: d.compact } }
    Component { id: musicC; MusicPage { phone: d.phone; compact: d.compact } }

    // along the bottom: the pages and a home bar, or a flip phone's soft keys
    Item {
        id: foot
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: d.look === "keitai" ? 28 : d.look === "slab" ? 52 : 40
        PagePills {
            visible: d.look !== "keitai" && d.pages.length > 1
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: d.look === "slab" ? 4 : 8 }
            pages: d.pages
            current: d.index
            onPicked: i => { d.phone.panel = ""; d.phone.page = d.pages[i]; }
        }
        // the home bar: back to the first page
        Rectangle {
            visible: d.look === "slab"
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 9 }
            width: 118; height: 5; radius: 2.5
            color: Theme.alpha(Theme.ink, homeHover.containsMouse ? 0.85 : 0.55)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            MouseArea {
                id: homeHover
                anchors { fill: parent; margins: -10 }
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { d.phone.panel = ""; d.phone.page = d.pages[0]; }
            }
        }
        // soft keys: what the keys either side of the d-pad do
        Rectangle {
            visible: d.look === "keitai"
            anchors.fill: parent
            color: Theme.alpha(Theme.surfaceLowest, 0.72)
            Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.ink, 0.08) }
            readonly property int n: d.pages.length
            Txt {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: d.phone.panel !== "" ? "‹ Back" : parent.n > 1 ? "‹ " + Actions.page[d.pages[(d.index + parent.n - 1) % parent.n]][1] : ""
                size: 11; weight: Font.Medium; color: Theme.inkDim
            }
            // where you are, or what the key under the pointer does
            Row {
                anchors.centerIn: parent
                spacing: 5
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: d.phone.hint === ""
                    name: Actions.page[d.phone.page]?.[0] ?? "home"; size: 13; fill: 1; color: Theme.primary
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: d.phone.hint !== "" ? d.phone.hint
                        : d.phone.panel === "wifi" ? "Wi-Fi" : d.phone.panel === "bluetooth" ? "Bluetooth" : Actions.page[d.phone.page]?.[1] ?? ""
                    size: 11; weight: Font.DemiBold
                    color: d.phone.hint !== "" ? Theme.primary : Theme.ink
                }
            }
            Txt {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                text: d.phone.panel === "" && parent.n > 1 ? Actions.page[d.pages[(d.index + 1) % parent.n]][1] + " ›" : ""
                size: 11; weight: Font.Medium; color: Theme.inkDim
            }
        }
    }

    // Wi-Fi and Bluetooth slide in over the pages; the pills and the home bar stay
    Item {
        id: over
        anchors { left: parent.left; right: parent.right; top: bar.bottom; bottom: foot.top }
        property string name: ""            // kept while it slides away
        visible: name !== ""
        clip: true
        Connections {
            target: d.phone
            function onPanelChanged() {
                if (d.phone.panel !== "") over.name = d.phone.panel;
                // the keys come back from the panel (the home screen's search takes them itself)
                else if (d.pages[d.index] !== "home") d.forceActiveFocus();
            }
        }
        Component.onCompleted: name = d.phone.panel
        property real k: d.phone.panel !== "" ? 1 : 0
        Behavior on k { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        onKChanged: if (k === 0) name = ""
        // the page behind fades nearly away, and takes no clicks meanwhile
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.surfaceLowest, 0.95 * over.k) }
        MouseArea { anchors.fill: parent; enabled: over.visible; acceptedButtons: Qt.AllButtons }
        Loader {
            id: panelView
            width: parent.width; height: parent.height
            x: (1 - over.k) * width * 0.6
            opacity: over.k
            sourceComponent: over.name === "wifi" ? wifiC : over.name === "bluetooth" ? btC : null
        }
    }
    Component { id: wifiC; WifiPanel { phone: d.phone; compact: d.compact } }
    Component { id: btC; BluetoothPanel { phone: d.phone; compact: d.compact } }

    // the glass, dark until the phone has woken up
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 1 - d.power
        visible: opacity > 0.001
    }
}
