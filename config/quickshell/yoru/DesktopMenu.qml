import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.parts

// the desktop's own menu: a right-click on the wallpaper (where no window or widget is)
// brings it up at the pointer. A clear sheet over the screen holds it and the keyboard
// while it's open: arrows and Enter, Escape or a click anywhere else closes it
Scope {
    id: menu

    required property var isle
    property bool shown: false
    property var screen: null
    property point at: Qt.point(0, 0)
    property int sel: -1

    function show(scr, x, y) { screen = scr; at = Qt.point(x, y); sel = -1; shown = true; }
    function close() { shown = false; }

    readonly property var rows: [
        { icon: "wallpaper", label: "Next wallpaper", run: () => Quickshell.execDetached(["yoru", "wall", "next"]) },
        { icon: "casino", label: "A random one", run: () => Quickshell.execDetached(["yoru", "wall", "random"]) },
        { icon: "imagesmode", label: "Wallpapers…", run: () => menu.isle.open("walls", menu.screen?.name ?? "") },
        { icon: "favorite", label: "Love this wallpaper", run: () => Quickshell.execDetached(["yoru", "wall", "fav"]) },
        { line: true },
        { icon: "sticky_note_2", label: "A note here", run: () => Desk.addAt("notes", menu.screen?.name ?? "", menu.at.x, menu.at.y) },
        { icon: "widgets", label: "Edit the desktop", run: () => Desk.edit() },
        { line: true },
        { icon: "settings", label: "Settings", run: () => SettingsIndex.open("", "") }
    ]
    function pick(i) {
        const r = rows[i];
        if (!r || r.line) return;
        close();
        r.run();
    }
    function step(d) {
        let i = sel;
        do { i = (i + d + rows.length) % rows.length; } while (rows[i].line);
        sel = i;
    }

    LazyLoader {
        active: menu.shown && !!menu.screen
        PanelWindow {
            id: sheet
            screen: menu.screen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "yoru-menu"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: menu.close()
            }
            Item {
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) menu.close();
                    else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) menu.step(1);
                    else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) menu.step(-1);
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) menu.pick(menu.sel);
                    e.accepted = true;
                }
            }

            Rectangle {
                id: box
                // at the pointer, kept on the screen
                x: Math.min(menu.at.x, sheet.width - width - 8)
                y: Math.min(menu.at.y, sheet.height - height - 8)
                width: 236
                height: col.implicitHeight + 12
                radius: Theme.r(20)
                color: Theme.island
                border.width: Theme.border > 0 ? Theme.border : 1
                border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.outlineVariant, 0.45)
                // it opens out of the pointer
                transformOrigin: Item.TopLeft
                scale: 0.9; opacity: 0
                Component.onCompleted: { scale = 1; opacity = 1; }
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                MouseArea { anchors.fill: parent }      // clicks on the menu stay in it
                Column {
                    id: col
                    x: 6; y: 6
                    width: parent.width - 12
                    Repeater {
                        model: menu.rows
                        Item {
                            id: row
                            required property var modelData
                            required property int index
                            width: col.width
                            height: modelData.line ? 9 : 38
                            Rectangle {
                                visible: !!row.modelData.line
                                anchors.centerIn: parent
                                width: parent.width - 24; height: 1
                                color: Theme.alpha(Theme.outlineVariant, 0.6)
                            }
                            Rectangle {
                                visible: !row.modelData.line
                                anchors.fill: parent
                                radius: Theme.r(14)
                                color: menu.sel === row.index ? Theme.secondaryContainer : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                Icon {
                                    id: ic
                                    x: 12; anchors.verticalCenter: parent.verticalCenter
                                    name: row.modelData.icon ?? ""; size: 18
                                    color: menu.sel === row.index ? Theme.inkSecondaryContainer : Theme.inkDim
                                }
                                Txt {
                                    anchors { left: ic.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: row.modelData.label ?? ""; size: 13
                                    color: menu.sel === row.index ? Theme.inkSecondaryContainer : Theme.ink
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: menu.sel = row.index
                                    onClicked: menu.pick(row.index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
