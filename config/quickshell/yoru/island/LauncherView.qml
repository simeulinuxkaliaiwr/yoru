import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

// apps, fuzzy-matched and ranked by how often you open them; maths too
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "launcher"
    property string query: ""
    property var counts: ({})
    property string answer: ""

    implicitWidth: 620
    implicitHeight: 64 + (list.count > 0 ? Math.min(list.count, 7) * 54 + 14 : 0) + (answer !== "" ? 58 : 0)

    onShownChanged: {
        if (shown) { input.text = ""; input.forceActiveFocus(); list.currentIndex = 0; }
    }

    // ── how often each app was opened ───────────────────────────────
    FileView {
        id: store
        path: Theme.cacheDir + "/launches.json"
        printErrors: false
        onLoaded: { try { v.counts = JSON.parse(text()); } catch (e) {} }
    }
    function launch(e) {
        const c = Object.assign({}, counts);
        c[e.id] = (c[e.id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
        e.execute();
        isle.close();
    }

    // subsequence match: consecutive letters and word starts score highest
    function score(text, q) {
        text = text.toLowerCase();
        if (text.startsWith(q)) return 100 - text.length * 0.1;
        const at = text.indexOf(q);
        if (at >= 0) return 70 - at;
        let ti = 0, s = 0, run = 0;
        for (const ch of q) {
            const found = text.indexOf(ch, ti);
            if (found < 0) return -1;
            run = found === ti ? run + 1 : 0;
            s += 2 + run * 3 + (found === 0 || " -_.".includes(text[found - 1]) ? 6 : 0);
            ti = found + 1;
        }
        return s / 2;
    }

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    readonly property var results: {
        const q = query.trim().toLowerCase();
        const used = e => Math.log2(1 + (counts[e.id] ?? 0)) * 6;
        if (q === "")
            return apps.slice().sort((a, b) => used(b) - used(a) || a.name.localeCompare(b.name)).slice(0, 7);
        const out = [];
        for (const e of apps) {
            const s = Math.max(score(e.name, q), score(e.genericName ?? "", q) - 20,
                               score((e.keywords ?? []).join(" "), q) - 30, score(e.id, q) - 25);
            if (s > 0) out.push({ e: e, s: s + used(e) });
        }
        return out.sort((a, b) => b.s - a.s).slice(0, 30).map(r => r.e);
    }

    // ── maths, through qalc ─────────────────────────────────────────
    Process {
        id: calc
        stdout: StdioCollector {
            onStreamFinished: {
                const r = this.text.trim();
                v.answer = r !== "" && r !== v.query.trim() && !/error|warning/i.test(r) ? r : "";
            }
        }
    }
    Timer {
        id: calcSoon; interval: 120
        onTriggered: {
            const q = v.query.trim().replace(/^=/, "");
            if (/[0-9]/.test(q) && /[-+*/^%()]|\b(sqrt|sin|cos|to|in)\b/.test(q)) {
                calc.command = ["qalc", "-t", "-e", q];
                calc.running = true;
            } else v.answer = "";
        }
    }
    onQueryChanged: { calcSoon.restart(); list.currentIndex = 0; }

    // ── the search field ────────────────────────────────────────────
    Rectangle {
        id: field
        x: 12; y: 12
        width: parent.width - 24; height: 44
        radius: 22
        color: Theme.surfaceMid
        Icon { id: glass; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 20; color: Theme.primary }
        TextInput {
            id: input
            anchors { left: glass.right; leftMargin: 10; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            color: Theme.ink
            selectionColor: Theme.primaryContainer
            selectedTextColor: Theme.inkPrimaryContainer
            font { family: Theme.sans; pixelSize: 15 }
            onTextChanged: v.query = text
            Keys.onPressed: e => {
                const ctrl = e.modifiers & Qt.ControlModifier;
                if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J) || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) {
                    list.incrementCurrentIndex(); e.accepted = true;
                } else if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K) || e.key === Qt.Key_Backtab) {
                    list.decrementCurrentIndex(); e.accepted = true;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    if (v.answer !== "" && (list.count === 0 || v.query.trim().startsWith("="))) {
                        Quickshell.execDetached(["wl-copy", v.answer]); v.isle.close();
                    } else if (list.currentItem) v.launch(list.currentItem.modelData);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Escape) {
                    v.isle.close(); e.accepted = true;
                }
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: "Search apps, or do some maths"
                size: 15
                color: Theme.outline
            }
        }
    }

    // ── the answer, when the query is a sum ─────────────────────────
    Rectangle {
        id: answerRow
        visible: v.answer !== ""
        x: 12; y: field.y + field.height + 8
        width: parent.width - 24; height: 50
        radius: 18
        color: Theme.tertiaryContainer
        Icon { id: eq; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "calculate"; size: 22; fill: 1; color: Theme.inkTertiaryContainer }
        Txt {
            anchors { left: eq.right; leftMargin: 12; right: hint.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: v.answer; size: 17; weight: Font.DemiBold; color: Theme.inkTertiaryContainer
            font.family: Theme.mono
        }
        Txt { id: hint; anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
              text: "click to copy"; size: 11; color: Theme.inkTertiaryContainer; opacity: 0.7 }
        StateLayer { tint: Theme.inkTertiaryContainer; onClicked: { Quickshell.execDetached(["wl-copy", v.answer]); v.isle.close(); } }
    }

    // ── results ─────────────────────────────────────────────────────
    ListView {
        id: list
        x: 12
        y: (answerRow.visible ? answerRow.y + answerRow.height : field.y + field.height) + 8
        width: parent.width - 24
        height: Math.min(count, 7) * 54
        clip: true
        model: v.results
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.normal
        highlightMoveVelocity: -1
        highlight: Rectangle {
            radius: 18
            color: Theme.secondaryContainer
        }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: list.width
            height: 54
            Image {
                id: ico
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 32; height: 32
                sourceSize: Qt.size(64, 64)
                source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                asynchronous: true
            }
            Column {
                anchors { left: ico.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                Txt {
                    width: parent.width; text: row.modelData.name; size: 14; weight: Font.Medium
                    color: row.ListView.isCurrentItem ? Theme.inkSecondaryContainer : Theme.ink
                }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.genericName || row.modelData.comment || ""
                    size: 11
                    color: Theme.inkDim
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: v.launch(row.modelData)
            }
        }
    }
}
