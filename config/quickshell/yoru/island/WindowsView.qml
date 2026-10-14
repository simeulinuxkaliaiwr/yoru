import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// the window picker (mod+Tab): every window as a card, the most recently used
// first. Type to filter, arrows or Tab to move, Enter to go there.
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "windows"
    property string query: ""
    readonly property int cols: 4
    readonly property int cardW: 168
    readonly property int cardH: 132

    implicitWidth: cols * cardW + (cols - 1) * 10 + 36
    implicitHeight: 74 + (grid.count > 0 ? Math.min(2, Math.ceil(grid.count / cols)) * (cardH + 10) : 70) + 8

    onShownChanged: if (shown) { query = ""; grid.currentIndex = items.length > 1 ? 1 : 0; }
    onQueryChanged: grid.currentIndex = 0

    // the windows, by when they were last focused; the scratchpad stays out
    readonly property var items: {
        const ws = Wm.windows.filter(w => w.state !== "scratchpad");
        const rank = id => { const i = Wm.mru.indexOf(id); return i < 0 ? 1e6 + id : i; };
        const q = query.trim().toLowerCase();
        return ws.filter(w => q === "" || (w.title + " " + w.app_id).toLowerCase().includes(q))
                 .sort((a, b) => rank(a.id) - rank(b.id));
    }

    function entry(appId) { return DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId); }
    function icon(appId) { return Quickshell.iconPath(entry(appId)?.icon ?? appId, "application-x-executable"); }

    // one way for every compositor: the foreign-toplevel handle focuses it
    function go(w) {
        const same = Wm.toplevels.filter(t => t.appId === w.app_id);
        const t = same.find(t => t.title === w.title)
            ?? same[Wm.windows.filter(x => x.app_id === w.app_id).indexOf(w)] ?? same[0];
        isle.close();
        if (t) t.activate();
        else Wm.focusWorkspace(w.workspace);
    }

    function key(e) {
        const n = grid.count;
        if (n === 0) return false;
        if (e.key === Qt.Key_Right || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) { grid.currentIndex = (grid.currentIndex + 1) % n; return true; }
        if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) { grid.currentIndex = (grid.currentIndex + n - 1) % n; return true; }
        if (e.key === Qt.Key_Down) { grid.currentIndex = Math.min(n - 1, grid.currentIndex + cols); return true; }
        if (e.key === Qt.Key_Up) { grid.currentIndex = Math.max(0, grid.currentIndex - cols); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { go(items[grid.currentIndex]); return true; }
        if (e.key === Qt.Key_Delete && grid.currentItem) {
            const w = items[grid.currentIndex];
            Wm.toplevels.find(t => t.appId === w.app_id && t.title === w.title)?.close();
            return true;
        }
        return false;
    }

    Row {
        x: 22; y: 22
        spacing: 10
        Icon { name: "select_window"; size: 22; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: v.query === "" ? "Windows" : v.query
            size: 17; weight: Font.DemiBold
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: v.items.length + (v.query === "" ? " open  ·  type to filter, Enter to go, Del closes" : " found")
            size: 12; color: Theme.inkDim
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 82 }
        visible: grid.count === 0
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bedtime"; size: 26; color: Theme.outline }
        Txt { text: v.query === "" ? "No windows open" : "Nothing matches"; size: 12; color: Theme.outline }
    }

    GridView {
        id: grid
        x: 18; y: 64
        width: v.cols * (v.cardW + 10)
        height: Math.min(2, Math.ceil(count / v.cols)) * (v.cardH + 10)
        cellWidth: v.cardW + 10
        cellHeight: v.cardH + 10
        clip: true
        model: v.items
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: true
        highlightMoveDuration: Theme.normal
        highlight: Rectangle {
            width: v.cardW; height: v.cardH
            radius: Theme.r(22)
            color: Theme.primaryContainer
        }
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool sel: GridView.isCurrentItem
            width: v.cardW; height: v.cardH

            Rectangle {
                anchors.fill: parent
                radius: Theme.r(22)
                color: card.sel ? "transparent" : Theme.surfaceMid
                border.width: card.modelData.focused ? 2 : 0
                border.color: Theme.primary
            }
            Image {
                id: ico
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 18 }
                width: 52; height: 52
                sourceSize: Qt.size(104, 104)
                source: v.icon(card.modelData.app_id)
                asynchronous: true
                scale: card.sel ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            }
            Column {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                spacing: 1
                Txt {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: card.modelData.title || card.modelData.app_id
                    size: 12; weight: Font.Medium
                    color: card.sel ? Theme.inkPrimaryContainer : Theme.ink
                }
                Txt {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: (v.entry(card.modelData.app_id)?.name ?? card.modelData.app_id) + "  ·  " + card.modelData.workspace
                    size: 10
                    color: card.sel ? Theme.inkPrimaryContainer : Theme.inkDim
                    opacity: 0.8
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: grid.currentIndex = card.index
                onClicked: v.go(card.modelData)
            }
        }
    }
}
