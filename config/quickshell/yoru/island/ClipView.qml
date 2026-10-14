import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// cliphist, searchable, with a preview: images as pictures, text in full.
// Enter copies, shift+Delete forgets.
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "clip"
    property var entries: []            // [{ line, id, text, image, ext, size }]
    property string query: ""
    property var images: ({})           // id -> decoded file
    property var pending: ({})          // ids being decoded (not a binding source)
    property string fullText: ""        // the selected text entry, decoded
    readonly property string cache: Theme.cacheDir + "/clip"
    readonly property var cur: list.currentIndex >= 0 ? shownEntries[list.currentIndex] ?? null : null

    implicitWidth: 960
    implicitHeight: 64 + (list.count > 0 ? 8 * 52 + 16 : 70)

    readonly property var shownEntries: {
        const q = query.toLowerCase();
        return q === "" ? entries : entries.filter(e => e.text.toLowerCase().includes(q));
    }

    onShownChanged: if (shown) { query = ""; load.running = true; }
    onQueryChanged: list.currentIndex = 0
    onCurChanged: preview()

    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) { list.incrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) { list.decrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (cur) pick(cur); return true; }
        if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier)) { if (cur) forget(cur); return true; }
        return false;
    }

    Process {
        id: load
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                v.entries = this.text.split("\n").filter(l => l !== "").slice(0, 300).map(l => {
                    const tab = l.indexOf("\t");
                    const text = l.slice(tab + 1);
                    const img = text.match(/^\[\[ binary data (.*?) (png|jpe?g|webp|bmp|gif) (\d+x\d+) \]\]$/i);
                    return {
                        line: l, id: l.slice(0, tab), image: !!img,
                        text: img ? "Image" : text,
                        ext: img ? img[2].toLowerCase().replace("jpeg", "jpg") : "",
                        size: img ? img[3] : "", bytes: img ? img[1] : ""
                    };
                });
                list.currentIndex = 0;
                v.preview();
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

    // images are decoded once into the cache; the list asks as rows appear
    function image(e) {
        if (!e || !e.image) return "";
        if (images[e.id]) return images[e.id];
        if (!pending[e.id]) {
            pending[e.id] = true;
            decoder.createObject(v, { entry: e });
        }
        return "";
    }
    Component {
        id: decoder
        Process {
            id: job
            property var entry
            readonly property string path: v.cache + "/" + entry.id + "." + entry.ext
            running: true
            command: ["sh", "-c", 'mkdir -p "${2%/*}"; [ -s "$2" ] || printf "%s" "$1" | cliphist decode > "$2"', "sh", entry.line, path]
            onExited: {
                const m = Object.assign({}, v.images);
                m[entry.id] = "file://" + path;
                v.images = m;
                job.destroy();
            }
        }
    }
    // a text entry in full (the list only holds its first line)
    function preview() {
        fullText = "";
        if (!cur) return;
        if (cur.image) { image(cur); return; }
        textJob.command = ["sh", "-c", 'printf "%s" "$1" | cliphist decode | head -c 6000', "sh", cur.line];
        textJob.running = true;
    }
    Process {
        id: textJob
        stdout: StdioCollector { onStreamFinished: v.fullText = this.text }
    }

    // the search field
    Rectangle {
        id: field
        x: 12; y: 12
        width: parent.width - 24; height: 44
        radius: Theme.r(22)
        color: Theme.surfaceMid
        Icon { id: ic; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "content_paste"; size: 20; color: Theme.primary }
        Txt {
            id: typed
            anchors { left: ic.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: Math.min(implicitWidth, field.width - 70)
            text: v.query
            size: 15
            elide: Text.ElideLeft
        }
        Rectangle {
            anchors { left: typed.right; leftMargin: 1; verticalCenter: parent.verticalCenter }
            width: 2; height: 20; radius: Theme.r(1)
            color: Theme.primary
            visible: v.shown
            SequentialAnimation on opacity {
                running: v.shown; loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 0 }
                PauseAnimation { duration: 530 }
                NumberAnimation { to: 0; duration: 0 }
                PauseAnimation { duration: 530 }
            }
        }
        Txt {
            anchors { left: ic.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
            visible: v.query === ""
            text: "Clipboard history  ·  Enter copies  ·  shift+Del forgets"
            size: 15; color: Theme.outline
        }
        Txt {
            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            text: v.shownEntries.length + " items"
            size: 12; color: Theme.outline
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: field.bottom; topMargin: 14 }
        visible: list.count === 0
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "inventory_2"; size: 28; color: Theme.outline }
        Txt { text: v.query === "" ? "Nothing copied yet" : "No matches"; size: 12; color: Theme.outline }
    }

    // the list
    ListView {
        id: list
        x: 12; y: field.y + field.height + 8
        width: 470
        height: 8 * 52
        visible: count > 0
        clip: true
        spacing: 4
        model: v.shownEntries
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.normal
        highlightMoveVelocity: -1
        highlight: Rectangle { radius: Theme.r(16); color: Theme.secondaryContainer }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool sel: ListView.isCurrentItem
            width: list.width; height: 48
            ClippingRectangle {
                id: thumb
                x: 8; anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 32; radius: Theme.r(8)
                color: Theme.surfaceHigh
                Image {
                    anchors.fill: parent
                    visible: row.modelData.image
                    source: row.modelData.image ? v.image(row.modelData) : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(80, 64)
                    asynchronous: true
                }
                Icon {
                    anchors.centerIn: parent
                    visible: !row.modelData.image
                    name: /^https?:\/\//.test(row.modelData.text) ? "link" : /^#[0-9a-f]{6}$/i.test(row.modelData.text) ? "palette" : "notes"
                    size: 16
                    color: row.sel ? Theme.inkSecondaryContainer : Theme.outline
                }
                // a hex colour shows as itself
                Rectangle {
                    anchors.fill: parent
                    visible: /^#[0-9a-f]{6}$/i.test(row.modelData.text)
                    color: visible ? row.modelData.text : "transparent"
                }
            }
            Txt {
                anchors { left: thumb.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: row.modelData.image ? "Image  ·  " + row.modelData.size + "  ·  " + row.modelData.bytes : row.modelData.text.replace(/\s+/g, " ")
                size: 13
                color: row.sel ? Theme.inkSecondaryContainer : row.modelData.image ? Theme.inkDim : Theme.ink
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

    // the preview
    Rectangle {
        id: pane
        visible: list.count > 0
        anchors { left: list.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: list.top; bottom: list.bottom }
        radius: Theme.r(22)
        color: Theme.surfaceLow
        clip: true

        // an image, as large as fits
        ClippingRectangle {
            id: big
            visible: v.cur?.image ?? false
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            height: parent.height - 70
            radius: Theme.r(16)
            color: Theme.surfaceMid
            Image {
                id: bigImg
                anchors.fill: parent
                source: v.cur?.image ? (v.images[v.cur.id] ?? "") : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            }
        }
        // a hex colour, as a swatch
        Rectangle {
            visible: !(v.cur?.image ?? true) && /^#[0-9a-f]{6}$/i.test(v.cur?.text ?? "")
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            height: 120; radius: Theme.r(16)
            color: visible ? v.cur.text : "transparent"
        }
        // text, in full
        Flickable {
            visible: !(v.cur?.image ?? true)
            anchors { fill: parent; margins: 18; bottomMargin: 56 }
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Text {
                id: body
                width: parent.width
                text: v.fullText || (v.cur?.text ?? "")
                color: Theme.ink
                wrapMode: Text.WrapAnywhere
                textFormat: Text.PlainText
                // code and paths read better in mono
                readonly property bool code: /[{};<>]|^\s{2,}|\/\w+\/|=>|::/m.test(text)
                font { family: code ? Theme.mono : Theme.sans; pixelSize: code ? 12 : 14 }
                lineHeight: 1.15
            }
        }
        // what it is, along the bottom
        Row {
            anchors { left: parent.left; bottom: parent.bottom; margins: 16 }
            spacing: 8
            Icon {
                name: v.cur?.image ? "image" : /^https?:\/\//.test(v.cur?.text ?? "") ? "link" : "notes"
                size: 16; color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                size: 12; color: Theme.inkDim
                text: !v.cur ? "" : v.cur.image ? v.cur.ext.toUpperCase() + "  ·  " + v.cur.size + "  ·  " + v.cur.bytes
                    : (v.fullText || v.cur.text).length + " characters  ·  " + ((v.fullText || v.cur.text).split("\n").length) + " lines"
            }
        }
        Rectangle {
            anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
            width: copyRow.implicitWidth + 24; height: 34; radius: Theme.r(17)
            color: Theme.primary
            Row {
                id: copyRow
                anchors.centerIn: parent
                spacing: 6
                Icon { name: "content_copy"; size: 16; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
                Txt { text: "Copy"; size: 12; weight: Font.DemiBold; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
            }
            StateLayer { tint: Theme.inkPrimary; onClicked: if (v.cur) v.pick(v.cur) }
        }
    }
}
