import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

// the projects (mod+g): ~/Projects, the most recently worked on first, with
// what git and the open terminals say about the one picked. Enter goes to
// its terminal (or opens one here), shift+Enter always opens a new one.
// kehai-proj (~/Projects/kehai) does the work; this only shows it.
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "projects"
    property var projects: []           // kehai-proj list --json
    property var info: null             // kehai-proj info, for cur
    property string query: ""
    property bool missing: false        // no kehai-proj on PATH
    readonly property var cur: list.currentIndex >= 0 ? shownProjects[list.currentIndex] ?? null : null

    implicitWidth: 960
    implicitHeight: 64 + (list.count > 0 ? 8 * 52 + 16 : 70)

    readonly property var shownProjects: {
        const q = query.toLowerCase().trim();
        return q === "" ? projects : projects.filter(p => (p.name + " " + p.branch + " " + p.subject).toLowerCase().includes(q));
    }

    onShownChanged: if (shown) { query = ""; load.running = true; }
    onQueryChanged: list.currentIndex = 0
    onCurChanged: details()

    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J)) { list.incrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K)) { list.decrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (cur) go(cur, e.modifiers & Qt.ShiftModifier);
            return true;
        }
        return false;
    }

    function go(p, fresh) {
        Quickshell.execDetached(fresh ? ["kehai-proj", "open", "--new", p.path] : ["kehai-proj", "open", p.path]);
        isle.close();
    }

    function ago(t) {
        const s = Date.now() / 1000 - t;
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + "m" : s < 86400 ? Math.floor(s / 3600) + "h"
             : s < 86400 * 60 ? Math.floor(s / 86400) + "d" : Math.floor(s / 86400 / 30) + "mo";
    }
    // a status letter's colour: added, deleted, untracked, the rest changed
    function stColour(st) {
        return st.includes("?") ? Theme.outline : st.includes("D") ? Theme.danger
             : st.includes("A") ? Theme.primary : Theme.tertiary;
    }

    Process {
        id: load
        command: ["kehai-proj", "list", "--json"]
        onExited: code => v.missing = code === 127
        stdout: StdioCollector {
            onStreamFinished: {
                try { v.projects = JSON.parse(this.text); } catch (e) { v.projects = []; }
                list.currentIndex = 0;
                v.details();
            }
        }
    }

    // one at a time: a pick made while one runs is asked for when it ends,
    // and only the latest pick
    property string want: ""            // the path the pane should show
    property string asked: ""           // the path infoJob is fetching
    function details() {
        want = cur ? cur.path : "";
        if (want === "") { info = null; return; }
        if (infoJob.running) return;
        asked = want;
        infoJob.command = ["kehai-proj", "info", want];
        infoJob.running = true;
    }
    Process {
        id: infoJob
        stdout: StdioCollector {
            onStreamFinished: {
                let r = null;
                try { r = JSON.parse(this.text); } catch (e) {}
                if (r && r.path === v.want) v.info = r;
            }
        }
        onExited: if (v.asked !== v.want) Qt.callLater(v.details)
    }

    // the search field
    Rectangle {
        id: field
        x: 12; y: 12
        width: parent.width - 24; height: 44
        radius: Theme.r(22)
        color: Theme.surfaceMid
        Icon { id: ic; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "folder_open"; size: 20; color: Theme.primary }
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
            text: "Projects  ·  Enter goes  ·  shift+Enter opens a new terminal"
            size: 15; color: Theme.outline
        }
        Txt {
            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            text: v.shownProjects.length + " projects"
            size: 12; color: Theme.outline
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: field.bottom; topMargin: 14 }
        visible: list.count === 0
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: v.missing ? "error" : "folder_off"; size: 28; color: Theme.outline }
        Txt {
            text: v.missing ? "kehai-proj isn't installed" : v.query === "" ? "No projects" : "No matches"
            size: 12; color: Theme.outline
        }
    }

    // the list
    ListView {
        id: list
        x: 12; y: field.y + field.height + 8
        width: 430
        height: 8 * 52
        visible: count > 0
        clip: true
        spacing: 4
        model: v.shownProjects
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.normal
        highlightMoveVelocity: -1
        highlight: Rectangle { radius: Theme.r(16); color: Theme.secondaryContainer }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool sel: ListView.isCurrentItem
            readonly property color ink: sel ? Theme.inkSecondaryContainer : Theme.ink
            readonly property color dim: sel ? Theme.inkSecondaryContainer : Theme.inkDim
            width: list.width; height: 48

            Icon {
                id: glyph
                x: 14; anchors.verticalCenter: parent.verticalCenter
                // a terminal is open there: it shows, filled
                name: row.modelData.open > 0 ? "terminal" : row.modelData.git ? "folder_code" : "folder"
                fill: row.modelData.open > 0 ? 1 : 0
                size: 20
                color: row.modelData.open > 0 ? Theme.primary : row.dim
            }
            Column {
                anchors { left: glyph.right; leftMargin: 12; right: marks.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 1
                Txt { width: parent.width; text: row.modelData.name; size: 13; weight: Font.DemiBold; color: row.ink }
                Txt {
                    width: parent.width
                    text: row.modelData.git ? row.modelData.branch + "  ·  " + row.modelData.subject : "not a git repository"
                    size: 11; color: row.dim; opacity: 0.85
                }
            }
            Row {
                id: marks
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 10
                Row {
                    visible: row.modelData.changed > 0
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: 7; height: 7; radius: Theme.r(4); color: Theme.tertiary; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: row.modelData.changed; size: 11; color: row.dim }
                }
                Row {
                    visible: row.modelData.ahead > 0
                    spacing: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Icon { name: "arrow_upward"; size: 13; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: row.modelData.ahead; size: 11; color: row.dim }
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; horizontalAlignment: Text.AlignRight
                    text: v.ago(row.modelData.at); size: 11; color: row.dim
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onEntered: list.currentIndex = row.index
                // a middle click: a new terminal, as shift+Enter
                onClicked: e => v.go(row.modelData, e.button === Qt.MiddleButton)
            }
        }
    }

    // what git and the terminals say about the one picked
    Rectangle {
        id: pane
        visible: list.count > 0 && v.cur !== null
        anchors { left: list.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: list.top; bottom: list.bottom }
        radius: Theme.r(22)
        color: Theme.surfaceLow
        clip: true

        readonly property var p: v.cur
        readonly property var i: v.info && v.cur && v.info.path === v.cur.path ? v.info : null

        Column {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 4
            Txt { width: parent.width; text: pane.p?.name ?? ""; size: 20; weight: Font.DemiBold }
            Txt { width: parent.width; text: (pane.p?.path ?? "").replace(Quickshell.env("HOME"), "~"); size: 11; color: Theme.inkDim; font.family: Theme.mono }
        }

        // the facts in a row of chips
        Flow {
            id: chips
            anchors { left: parent.left; right: parent.right; top: head.bottom; margins: 18; topMargin: 12 }
            spacing: 6
            component Chip: Rectangle {
                id: chip
                property string icon
                property string label
                property color tint: Theme.inkDim
                width: chipRow.implicitWidth + 20; height: 26; radius: Theme.r(13)
                color: Theme.surfaceMid
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5
                    Icon { name: chip.icon; size: 14; color: chip.tint; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: chip.label; size: 11; color: Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Chip { visible: pane.p?.git ?? false; icon: "fork_right"; label: pane.p?.branch ?? ""; tint: Theme.primary }
            Chip { visible: (pane.p?.changed ?? 0) > 0; icon: "edit"; label: (pane.p?.changed ?? 0) + " changed"; tint: Theme.tertiary }
            Chip { visible: (pane.p?.ahead ?? 0) > 0; icon: "arrow_upward"; label: (pane.p?.ahead ?? 0) + " not pushed"; tint: Theme.primary }
            Chip { visible: (pane.p?.behind ?? 0) > 0; icon: "arrow_downward"; label: (pane.p?.behind ?? 0) + " behind"; tint: Theme.danger }
            Chip { visible: (pane.p?.git ?? false) && (pane.p?.ahead ?? 0) < 0; icon: "cloud_off"; label: "no upstream" }
            Chip {
                visible: (pane.p?.open ?? 0) > 0
                icon: "terminal"; tint: Theme.primary
                label: (pane.p?.open ?? 0) === 1 ? "terminal open" : (pane.p?.open ?? 0) + " terminals open"
            }
        }

        Flickable {
            anchors { left: parent.left; right: parent.right; top: chips.bottom; bottom: parent.bottom; margins: 18; topMargin: 14; bottomMargin: 56 }
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: body
                width: parent.width
                spacing: 4

                // what the terminals there are doing
                Repeater {
                    model: pane.i?.terminals.filter(t => t.cmd !== "") ?? []
                    Row {
                        required property var modelData
                        spacing: 8
                        width: body.width
                        Icon { name: "play_arrow"; size: 14; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        Txt { width: parent.width - 22; text: modelData.cmd; size: 12; font.family: Theme.mono }
                    }
                }

                Txt {
                    visible: (pane.i?.changed.length ?? 0) > 0
                    text: "Changed"; size: 11; weight: Font.DemiBold; color: Theme.inkDim
                    topPadding: 2
                }
                Repeater {
                    model: pane.i?.changed ?? []
                    Row {
                        required property var modelData
                        spacing: 8
                        width: body.width
                        Txt { width: 18; text: modelData.st.trim(); size: 11; font.family: Theme.mono; color: v.stColour(modelData.st) }
                        Txt { width: parent.width - 26; text: modelData.path; size: 12; font.family: Theme.mono; elide: Text.ElideMiddle }
                    }
                }

                Txt {
                    visible: (pane.i?.commits.length ?? 0) > 0
                    text: "Commits"; size: 11; weight: Font.DemiBold; color: Theme.inkDim
                    topPadding: 8
                }
                Repeater {
                    model: pane.i?.commits ?? []
                    Row {
                        id: commit
                        required property var modelData
                        readonly property bool local: pane.i.unpushed.includes(modelData.hash)
                        spacing: 8
                        width: body.width
                        // not pushed yet: a dot in the accent
                        Rectangle {
                            width: 6; height: 6; radius: Theme.r(3)
                            anchors.verticalCenter: parent.verticalCenter
                            color: commit.local ? Theme.primary : "transparent"
                            border.width: commit.local ? 0 : 1
                            border.color: Theme.outline
                        }
                        Txt { width: 56; text: modelData.hash; size: 11; font.family: Theme.mono; color: Theme.inkDim }
                        Txt { width: parent.width - 134; text: modelData.subject; size: 12 }
                        Txt { width: 40; horizontalAlignment: Text.AlignRight; text: v.ago(modelData.at); size: 11; color: Theme.inkDim }
                    }
                }
            }
        }

        // go, or a new terminal
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
            spacing: 8
            Rectangle {
                width: newRow.implicitWidth + 24; height: 34; radius: Theme.r(17)
                color: Theme.surfaceMid
                Row {
                    id: newRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: "add"; size: 16; color: Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: "New terminal"; size: 12; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
                StateLayer { tint: Theme.ink; onClicked: if (v.cur) v.go(v.cur, true) }
            }
            Rectangle {
                width: goRow.implicitWidth + 24; height: 34; radius: Theme.r(17)
                color: Theme.primary
                Row {
                    id: goRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: (pane.p?.open ?? 0) > 0 ? "arrow_forward" : "terminal"; size: 16; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
                    Txt {
                        text: (pane.p?.open ?? 0) > 0 ? "Go there" : "Open here"
                        size: 12; weight: Font.DemiBold; color: Theme.inkPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                StateLayer { tint: Theme.inkPrimary; onClicked: if (v.cur) v.go(v.cur, false) }
            }
        }
    }
}
