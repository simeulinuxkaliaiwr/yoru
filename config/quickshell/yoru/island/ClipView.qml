import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// cliphist, searchable, with a preview: images as pictures, text in full. Enter pastes it
// into the window you were in (clip.paste; Shift+Enter only copies), Ctrl+P pins it (pins
// stay at the top, kept apart from cliphist), Tab picks what kind shows, Shift+Delete forgets
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

    // what kind each is, for the chips
    readonly property var kinds: [["all", "All"], ["text", "Text"], ["links", "Links"], ["images", "Images"], ["colours", "Colours"]]
    property string kind: "all"
    function kindOf(e) {
        return e.image ? "images" : /^https?:\/\//.test(e.text) ? "links" : /^#[0-9a-f]{6}$/i.test(e.text.trim()) ? "colours" : "text";
    }
    readonly property var shownEntries: {
        const q = query.toLowerCase();
        const fits = e => (kind === "all" || kindOf(e) === kind) && (q === "" || e.text.toLowerCase().includes(q));
        // a pinned one isn't listed twice
        const pinnedText = new Set(pins.filter(p => !p.image).map(p => p.text));
        const pinnedFrom = new Set(pins.map(p => p.from).filter(f => f));
        return pins.filter(fits).concat(entries.filter(e => fits(e) && !pinnedFrom.has(e.id) && (e.image || !pinnedText.has(e.text))));
    }

    // the window you were in, for pasting back into (terminals take Ctrl+Shift+V)
    property string target: ""
    readonly property var terminals: ["foot", "footclient", "kitty", "alacritty", "ghostty", "com.mitchellh.ghostty", "org.wezfurlong.wezterm",
                                      "wezterm", "konsole", "org.gnome.terminal", "org.gnome.console", "xterm", "terminator", "tilix"]
    onShownChanged: if (shown) { query = ""; kind = "all"; target = Wm.windows.find(w => w.focused)?.app_id ?? ""; load.running = true; }
    onQueryChanged: list.currentIndex = 0
    onKindChanged: list.currentIndex = 0
    onCurChanged: preview()

    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier;
        if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) { list.incrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) { list.decrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (cur) pick(cur, !shift && Config.o.clip.paste); return true; }
        if (e.key === Qt.Key_Delete && shift) { if (cur) forget(cur); return true; }
        if (ctrl && e.key === Qt.Key_P) { if (cur) togglePin(cur); return true; }
        if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
            const i = kinds.findIndex(k => k[0] === kind), n = kinds.length;
            kind = kinds[(i + (e.key === Qt.Key_Backtab ? n - 1 : 1)) % n][0];
            return true;
        }
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
    // copied, then (paste) typed into the window you were in once the island has gone and it
    // has the keyboard back; with no wtype it's only copied
    function pick(e, paste) {
        if (e.pin) {
            if (e.image) Quickshell.execDetached(["sh", "-c", 'wl-copy --type "image/$2" < "$1"', "sh", e.file, e.ext === "jpg" ? "jpeg" : e.ext]);
            else Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", e.text]);
        } else {
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", e.line]);
        }
        isle.close();
        if (paste) { pasteSoon.terminal = terminals.includes(target.toLowerCase()); pasteSoon.restart(); }
    }
    Timer {
        id: pasteSoon
        interval: 220
        property bool terminal: false
        onTriggered: Quickshell.execDetached(["sh", "-c", 'command -v wtype >/dev/null || exit 0; if [ "$1" = 1 ]; then exec wtype -M ctrl -M shift -k v -m shift -m ctrl; else exec wtype -M ctrl -k v -m ctrl; fi', "sh", terminal ? "1" : "0"])
    }
    function forget(e) {
        if (e.pin) { togglePin(e); return; }
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", e.line]);
        entries = entries.filter(x => x !== e);
    }

    // pins: kept in ~/.cache/yoru/clip-pins.json (their pictures beside it), so cliphist
    // forgetting old entries never takes them
    property var pins: []               // [{ pin, id, text, image, file, ext, size }]
    readonly property string pinDir: Theme.cacheDir + "/clip-pins"
    FileView {
        id: pinStore
        path: Theme.cacheDir + "/clip-pins.json"
        printErrors: false
        onLoaded: { try { v.pins = JSON.parse(text()).map(p => Object.assign({ pin: true }, p)); } catch (e) {} }
    }
    function savePins() { pinStore.setText(JSON.stringify(pins.map(p => ({ id: p.id, from: p.from, text: p.text, image: p.image, file: p.file, ext: p.ext, size: p.size })))); }
    function togglePin(e) {
        if (e.pin) {
            if (e.image) Quickshell.execDetached(["rm", "-f", e.file]);
            pins = pins.filter(p => p.id !== e.id);
            savePins();
            return;
        }
        pinJob.entry = e;
        const id = "p" + Date.now();
        pinJob.pinId = id;
        pinJob.file = e.image ? pinDir + "/" + id + "." + e.ext : "";
        pinJob.command = e.image
            ? ["sh", "-c", 'mkdir -p "${2%/*}" && printf "%s" "$1" | cliphist decode > "$2"', "sh", e.line, pinJob.file]
            : ["sh", "-c", 'printf "%s" "$1" | cliphist decode', "sh", e.line];
        pinJob.running = true;
    }
    Process {
        id: pinJob
        property var entry
        property string pinId
        property string file
        stdout: StdioCollector {
            onStreamFinished: {
                const e = pinJob.entry;
                const p = e.image ? { pin: true, id: pinJob.pinId, from: e.id, text: "Image", image: true, file: pinJob.file, ext: e.ext, size: e.size }
                                  : { pin: true, id: pinJob.pinId, from: e.id, text: this.text, image: false };
                v.pins = [p].concat(v.pins);
                v.savePins();
            }
        }
    }

    // clearing it all asks twice; pins stay
    property bool sure: false
    Timer { id: unsure; interval: 3000; onTriggered: v.sure = false }
    function clearAll() {
        if (!sure) { sure = true; unsure.restart(); return; }
        sure = false;
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    // images are decoded once into the cache; the list asks as rows appear
    function image(e) {
        if (!e || !e.image) return "";
        if (e.pin) return "file://" + e.file;
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
        if (cur.pin) { fullText = cur.text; return; }
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
        width: list.width; height: 44
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
            text: Config.o.clip.paste ? "Search  ·  Enter pastes, Shift+Enter copies" : "Search  ·  Enter copies"
            size: 14; color: Theme.outline
        }
        Txt {
            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            text: v.shownEntries.length
            size: 12; color: Theme.outline
        }
    }

    // what kind shows (Tab), and clearing it all
    Row {
        anchors { left: field.right; leftMargin: 12; verticalCenter: field.verticalCenter }
        spacing: 4
        Repeater {
            model: v.kinds
            Rectangle {
                required property var modelData
                readonly property bool on: v.kind === modelData[0]
                height: 30; width: klabel.implicitWidth + 22
                radius: on ? Theme.r(10) : 15
                color: on ? Theme.secondaryContainer : "transparent"
                border.width: on ? 0 : 1
                border.color: Theme.outlineVariant
                Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Txt { id: klabel; anchors.centerIn: parent; text: parent.modelData[1]; size: 12; weight: Font.Medium
                      color: parent.on ? Theme.inkSecondaryContainer : Theme.inkDim }
                StateLayer { onClicked: v.kind = parent.modelData[0] }
            }
        }
    }
    Rectangle {
        anchors { right: parent.right; rightMargin: 12; verticalCenter: field.verticalCenter }
        height: 30; width: clearRow.implicitWidth + 22
        radius: 15
        color: v.sure ? Theme.danger : "transparent"
        border.width: v.sure ? 0 : 1
        border.color: Theme.outlineVariant
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Row {
            id: clearRow
            anchors.centerIn: parent
            spacing: 4
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "delete_sweep"; size: 16; color: v.sure ? Theme.inkPrimary : Theme.inkDim }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: v.sure ? "Sure?" : "Clear"; size: 12; weight: Font.Medium; color: v.sure ? Theme.inkPrimary : Theme.inkDim }
        }
        StateLayer { onClicked: v.clearAll() }
    }

    Column {
        anchors { horizontalCenter: list.horizontalCenter; top: field.bottom; topMargin: 14 }
        visible: list.count === 0
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "inventory_2"; size: 28; color: Theme.outline }
        Txt { text: v.query === "" && v.kind === "all" ? "Nothing copied yet" : "No matches"; size: 12; color: Theme.outline }
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
                anchors { left: thumb.right; leftMargin: 12; right: pinMark.visible ? pinMark.left : parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: row.modelData.image ? "Image  ·  " + row.modelData.size + (row.modelData.bytes ? "  ·  " + row.modelData.bytes : "") : row.modelData.text.replace(/\s+/g, " ")
                size: 13
                color: row.sel ? Theme.inkSecondaryContainer : row.modelData.image ? Theme.inkDim : Theme.ink
            }
            Icon {
                id: pinMark
                visible: row.modelData.pin === true
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                name: "keep"; size: 16; fill: 1
                color: row.sel ? Theme.inkSecondaryContainer : Theme.primary
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: v.pick(row.modelData, Config.o.clip.paste)
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
                source: v.cur?.image ? (v.cur.pin ? "file://" + v.cur.file : v.images[v.cur.id] ?? "") : ""
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
                text: !v.cur ? "" : v.cur.image ? v.cur.ext.toUpperCase() + "  ·  " + v.cur.size + (v.cur.bytes ? "  ·  " + v.cur.bytes : "")
                    : (v.fullText || v.cur.text).length + " characters  ·  " + ((v.fullText || v.cur.text).split("\n").length) + " lines"
            }
        }
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
            spacing: 6
            // pinned ones stay at the top (Ctrl+P)
            Rectangle {
                width: pinRow.implicitWidth + 24; height: 34; radius: Theme.r(17)
                color: "transparent"
                border.width: 1; border.color: Theme.outlineVariant
                Row {
                    id: pinRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: "keep"; size: 16; fill: v.cur?.pin ? 1 : 0; color: Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: v.cur?.pin ? "Unpin" : "Pin"; size: 12; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
                StateLayer { onClicked: if (v.cur) v.togglePin(v.cur) }
            }
            Rectangle {
                width: copyRow.implicitWidth + 24; height: 34; radius: Theme.r(17)
                color: Theme.primary
                Row {
                    id: copyRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: Config.o.clip.paste ? "content_paste_go" : "content_copy"; size: 16; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: Config.o.clip.paste ? "Paste" : "Copy"; size: 12; weight: Font.DemiBold; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
                }
                StateLayer { tint: Theme.inkPrimary; onClicked: if (v.cur) v.pick(v.cur, Config.o.clip.paste) }
            }
        }
    }
}
