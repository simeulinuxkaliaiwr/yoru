import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

// cliphist, searchable: Enter copies, shift+Delete forgets
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "clip"
    property var entries: []            // [{ id, text, image }]
    property string query: ""

    implicitWidth: 620
    implicitHeight: 64 + (list.count > 0 ? Math.min(list.count, 8) * 48 + 14 : 64)

    readonly property var shownEntries: {
        const q = query.toLowerCase();
        return q === "" ? entries : entries.filter(e => e.text.toLowerCase().includes(q));
    }

    onShownChanged: if (shown) { input.text = ""; input.forceActiveFocus(); load.running = true; }

    Process {
        id: load
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                v.entries = this.text.split("\n").filter(l => l !== "").slice(0, 200).map(l => {
                    const tab = l.indexOf("\t");
                    const text = l.slice(tab + 1);
                    const img = text.match(/^\[\[ binary data (.*?) (png|jpe?g|webp|bmp) (\d+x\d+) \]\]$/);
                    return { line: l, text: img ? "Image · " + img[3] + " · " + img[1] : text, image: !!img };
                });
                list.currentIndex = 0;
            }
        }
    }
    function pick(e) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", e.line]);
        isle.close();
    }
    function forget(e) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", e.line]);
        entries = entries.filter(x => x !== e);
    }

    Rectangle {
        id: field
        x: 12; y: 12
        width: parent.width - 24; height: 44
        radius: 22
        color: Theme.surfaceMid
        Icon { id: ic; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "content_paste"; size: 20; color: Theme.primary }
        TextInput {
            id: input
            anchors { left: ic.right; leftMargin: 10; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            color: Theme.ink
            font { family: Theme.sans; pixelSize: 15 }
            onTextChanged: { v.query = text; list.currentIndex = 0; }
            Keys.onPressed: e => {
                const ctrl = e.modifiers & Qt.ControlModifier;
                if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) { list.incrementCurrentIndex(); e.accepted = true; }
                else if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) { list.decrementCurrentIndex(); e.accepted = true; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (list.currentItem) v.pick(list.currentItem.modelData); e.accepted = true; }
                else if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier)) { if (list.currentItem) v.forget(list.currentItem.modelData); e.accepted = true; }
                else if (e.key === Qt.Key_Escape) { v.isle.close(); e.accepted = true; }
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: "Clipboard history  ·  shift+Del forgets"
                size: 15; color: Theme.outline
            }
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: field.bottom; topMargin: 14 }
        visible: list.count === 0
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "inventory_2"; size: 28; color: Theme.outline }
        Txt { text: v.query === "" ? "Nothing copied yet" : "No matches"; size: 12; color: Theme.outline }
    }

    ListView {
        id: list
        x: 12; y: field.y + field.height + 8
        width: parent.width - 24
        height: Math.min(count, 8) * 48
        clip: true
        model: v.shownEntries
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.normal
        highlightMoveVelocity: -1
        highlight: Rectangle { radius: 16; color: Theme.secondaryContainer }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: list.width; height: 48
            Icon {
                id: kind; x: 14
                anchors.verticalCenter: parent.verticalCenter
                name: row.modelData.image ? "image" : "notes"
                size: 18
                color: row.ListView.isCurrentItem ? Theme.inkSecondaryContainer : Theme.outline
            }
            Txt {
                anchors { left: kind.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                text: row.modelData.text.replace(/\s+/g, " ")
                size: 13
                color: row.ListView.isCurrentItem ? Theme.inkSecondaryContainer : Theme.ink
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: v.pick(row.modelData)
            }
        }
    }
}
