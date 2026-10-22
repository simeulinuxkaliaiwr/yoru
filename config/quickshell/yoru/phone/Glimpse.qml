import Quickshell
import Quickshell.Widgets
import QtQuick
import qs
import qs.desktop

// the phone's home screen, still: for the settings' preview, which shows the bodies with this
// in them instead of the live screen (that would start the shell's services a second time)
Item {
    id: g
    property string look: "slab"
    property real power: 1
    readonly property bool compact: height < 560
    readonly property var c: Config.o.phone
    // the ones you open most, then the rest
    readonly property var apps: { const m = Apps.most(); return m.concat(Apps.entries.filter(e => !m.includes(e))); }

    Backdrop { anchors.fill: parent; kind: g.c.screen }
    Column {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: g.compact ? 12 : 18; topMargin: g.look === "keitai" ? 34 : 60 }
        spacing: g.compact ? 10 : 18
        Item {
            width: parent.width
            visible: g.c.clock !== "none"
            height: face.implicitHeight * face.scale
            ClockFace {
                id: face
                anchors.horizontalCenter: parent.horizontalCenter
                style: g.c.clock === "none" ? "thin" : g.c.clock
                centred: true
                k: g.compact ? 0.34 : 0.5
                scale: Math.min(1, parent.width / Math.max(1, implicitWidth))
                transformOrigin: Item.Top
            }
        }
        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: Math.max(3, Math.min(5, g.c.columns))
            spacing: g.compact ? 18 : 26
            Repeater {
                model: g.apps.slice(0, Math.max(3, Math.min(5, g.c.columns)) * (g.compact ? 2 : 3))
                IconImage {
                    required property var modelData
                    implicitSize: g.compact ? 34 : 46
                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                }
            }
        }
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: 1 - g.power; visible: opacity > 0.001 }
}
