import QtQuick
import qs
import qs.parts
import qs.desktop

// the home screen: the clock (any of the desktop's styles), the weather, your apps and a
// dock of four. Typing searches them, from any page; Enter opens the chosen one, or brings
// it back if it's open. Right-click takes one off. What isn't an app (maths, the web, emoji,
// a command) goes on to the island's list
Item {
    id: home
    required property var phone
    property var display: null
    property bool live: false
    property bool compact: false
    property alias query: field.text
    property int sel: -1                        // the app the arrows have chosen
    readonly property var c: phone.c
    readonly property int pad: compact ? 12 : 18
    readonly property int cols: Math.max(3, Math.min(5, c.columns))

    // the settings' apps, else the ones you open most, made up with a few by name
    readonly property var all: {
        const pinned = c.apps ?? [];
        if (pinned.length > 0) return pinned.map(id => Apps.entry(id)).filter(e => e);
        const out = Apps.most().slice(0, 28);
        for (const e of Apps.entries.slice().sort((a, b) => a.name.localeCompare(b.name)))
            if (out.length < 20 && !out.includes(e)) out.push(e);
        return out;
    }
    readonly property bool searching: query.trim() !== ""
    readonly property var docked: c.dock && !compact ? all.slice(0, 4) : []
    readonly property var shown: searching ? Apps.search(query, 30) : all.slice(docked.length)

    onLiveChanged: {
        if (live) field.forceActiveFocus();
        else {
            sel = -1;
            if (field.activeFocus) display?.forceActiveFocus();
        }
    }

    function typeIn(t) {
        phone.panel = "";
        phone.page = "home";
        field.forceActiveFocus();
        field.insert(field.cursorPosition, t);
    }
    function clear() { field.text = ""; }
    function launch(e) {
        if (!e) return;
        if (!Apps.raise(e)) Apps.launch(e);
        phone.close();
    }
    function handOver() {
        const q = query;
        clear();
        phone.handOver(q);
    }
    // off the home screen: the rest become the settings' list (not from a search's results)
    function unpin(e) {
        if (searching || !all.includes(e)) return;
        c.apps = all.filter(a => a !== e).map(a => a.id);
    }
    function activate() {
        if (shown.length > 0 && (sel >= 0 || searching)) launch(shown[Math.max(0, Math.min(sel, shown.length - 1))]);
        else if (searching) handOver();
    }
    function key(e) {
        const n = grid.count;
        switch (e.key) {
        case Qt.Key_Return: case Qt.Key_Enter:
            if (sel < 0 && !searching) return false;
            activate();
            return true;
        case Qt.Key_Down:
            if (n > 0) sel = sel < 0 ? 0 : Math.min(n - 1, sel + cols);
            return true;
        case Qt.Key_Up:
            sel = sel < cols ? -1 : sel - cols;
            return true;
        // once in the grid the arrows stay there; before, they walk the pages
        case Qt.Key_Right:
            if (sel < 0) return false;
            sel = Math.min(n - 1, sel + 1);
            return true;
        case Qt.Key_Left:
            if (sel < 0) return false;
            if (sel > 0) sel--;
            return true;
        }
        return false;
    }

    Column {
        id: head
        x: home.pad
        y: home.compact ? 4 : 14
        width: parent.width - 2 * home.pad
        spacing: home.compact ? 6 : 12

        // the clock, folding away while you search
        Item {
            id: clockBox
            width: parent.width
            readonly property bool wanted: home.c.clock !== "none" && !home.searching
            height: wanted ? face.implicitHeight * face.scale : 0
            opacity: wanted ? 1 : 0
            visible: height > 0.5
            Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            ClockFace {
                id: face
                anchors.horizontalCenter: parent.horizontalCenter
                style: home.c.clock === "none" ? "thin" : home.c.clock
                centred: true
                k: home.compact ? 0.34 : 0.5
                scale: Math.min(1, clockBox.width / Math.max(1, implicitWidth))
                transformOrigin: Item.Top
            }
        }

        // the weather, and a way to the day
        Rectangle {
            visible: Weather.ready && !home.searching
            anchors.horizontalCenter: parent.horizontalCenter
            height: home.compact ? 24 : 30
            width: wrow.implicitWidth + 24
            radius: height / 2
            color: Theme.alpha(Theme.surfaceHigh, wx.containsMouse ? 0.8 : 0.55)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Row {
                id: wrow
                anchors.centerIn: parent
                spacing: 6
                Icon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon(Weather.code, Weather.day); size: home.compact ? 14 : 17; fill: 1; color: Theme.primary }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Weather.temp) + "°"; size: home.compact ? 11 : 13; weight: Font.DemiBold }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Weather.words(Weather.code); size: home.compact ? 11 : 12; color: Theme.inkDim }
            }
            MouseArea { id: wx; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: home.phone.go("today") }
        }

        // the search, which typing anywhere fills
        Rectangle {
            id: box
            width: parent.width
            height: home.compact ? 34 : 42
            radius: Theme.r(height / 2)
            color: Theme.alpha(Theme.surfaceHigh, field.activeFocus ? 0.82 : 0.6)
            border.width: field.activeFocus && home.searching ? 1.5 : 1
            border.color: field.activeFocus && home.searching ? Theme.primary : Theme.alpha(Theme.ink, 0.08)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Icon { id: glass; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: home.compact ? 16 : 19; color: Theme.inkDim }
            TextInput {
                id: field
                anchors { left: glass.right; leftMargin: 8; right: wipe.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                color: Theme.ink
                selectionColor: Theme.alpha(Theme.primary, 0.4)
                font { family: Theme.sans; pixelSize: home.compact ? 13 : 14 }
                clip: true
                Keys.onPressed: e => {
                    // the flip's keys before anything's typed: its shortcuts, not a search
                    if (field.text === "" && home.display && home.display.keypad(e.text)) e.accepted = true;
                    // searching, the arrows choose among what's found rather than move the caret
                    else if (home.searching && (e.key === Qt.Key_Left || e.key === Qt.Key_Right) && !(e.modifiers & Qt.ShiftModifier))
                        e.accepted = home.key(e);
                }
                onTextChanged: {
                    // the best match is chosen as you type (read from the text: the results may not have caught up yet)
                    home.sel = text.trim() !== "" ? 0 : -1;
                    // the list's own kinds of search: emoji, the web, a command, maths
                    if (text.length === 1 && ":?>=".includes(text)) home.handOver();
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text === ""
                    text: home.phone.c.skin === "flip" ? "Type to search" : "Search apps"
                    size: home.compact ? 13 : 14; color: Theme.outline
                }
            }
            IconButton {
                id: wipe
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                size: home.compact ? 24 : 30
                icon: "close"
                visible: home.searching
                onClicked: { home.clear(); field.forceActiveFocus(); }
            }
            MouseArea { anchors.fill: parent; z: -1; cursorShape: Qt.IBeamCursor; onClicked: field.forceActiveFocus() }
        }
    }

    // the apps
    GridView {
        id: grid
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: dock.visible ? dock.top : parent.bottom
                  leftMargin: home.pad - 4; rightMargin: home.pad - 4; topMargin: home.compact ? 6 : 14; bottomMargin: 6 }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: width / home.cols
        // whole rows only: the last one stretches the rest rather than showing half of itself
        readonly property real row: home.c.labels ? (home.compact ? 70 : 88) : (home.compact ? 56 : 70)
        cellHeight: Math.max(row, height / Math.max(1, Math.floor(height / row)))
        model: home.shown
        currentIndex: home.sel
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)
        delegate: AppCell {
            width: grid.cellWidth
            height: grid.cellHeight
            chosen: home.sel === index
            compact: home.compact
            labels: home.c.labels
            onOpened: home.launch(modelData)
            onDropped: home.unpin(modelData)
        }
        add: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Theme.fast } }
    }

    // found nothing: the island's list may know
    Column {
        visible: home.searching && home.shown.length === 0
        anchors { horizontalCenter: parent.horizontalCenter; top: head.bottom; topMargin: 36 }
        width: parent.width - 2 * home.pad
        spacing: 6
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "travel_explore"; size: 30; color: Theme.outline }
        Txt { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "No app called “" + home.query.trim() + "”"; size: 13; color: Theme.inkDim }
        Txt { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Enter asks the island: the web, maths, a command"; size: 11; color: Theme.outline; wrapMode: Text.Wrap }
    }

    // the dock: the first four, on a shelf
    Rectangle {
        id: dock
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: home.pad; rightMargin: home.pad; bottomMargin: 4 }
        height: 78
        radius: Theme.r(32)
        visible: home.docked.length > 0 && opacity > 0
        opacity: home.searching ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        color: Theme.alpha(Theme.surfaceLowest, 0.42)
        border.width: Theme.border > 0 ? Theme.border : 1
        border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.ink, 0.08)
        Row {
            anchors.centerIn: parent
            spacing: Math.max(4, (dock.width - 24 - home.docked.length * 62) / Math.max(1, home.docked.length - 1))
            Repeater {
                model: home.docked
                AppCell {
                    width: 62; height: 62
                    compact: false
                    labels: false
                    docked: true
                    onOpened: home.launch(modelData)
                    onDropped: home.unpin(modelData)
                }
            }
        }
    }
}
