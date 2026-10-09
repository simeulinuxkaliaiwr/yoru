import Quickshell
import QtQuick
import qs
import qs.parts

// leaving: lock, sleep, log out, restart, shut down
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "power"
    property int sel: 0
    implicitWidth: 500
    implicitHeight: 176

    readonly property var actions: [
        { icon: "lock", label: "Lock", cmd: ["aro-lock", "-f"] },
        { icon: "bedtime", label: "Sleep", cmd: ["systemctl", "suspend"] },
        { icon: "logout", label: "Log out", cmd: ["aroctl", "dispatch", "quit"] },
        { icon: "restart_alt", label: "Restart", cmd: ["systemctl", "reboot"] },
        { icon: "power_settings_new", label: "Shut down", cmd: ["systemctl", "poweroff"] },
    ]
    onShownChanged: if (shown) { sel = 0; keys.forceActiveFocus(); }
    function run(i) { isle.close(); Quickshell.execDetached(actions[i].cmd); }

    Txt { anchors.horizontalCenter: parent.horizontalCenter; y: 22; text: "Leaving so soon?"; size: 16; weight: Font.DemiBold }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 62 }
        spacing: 14
        Repeater {
            model: v.actions
            Column {
                id: act
                required property var modelData
                required property int index
                readonly property bool on: v.sel === index
                spacing: 8
                Rectangle {
                    width: 76; height: 64
                    radius: act.on ? 22 : 32
                    color: act.on ? (act.index === 4 ? Theme.danger : Theme.primary) : Theme.surfaceMid
                    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Icon {
                        anchors.centerIn: parent
                        name: act.modelData.icon; size: 26; fill: act.on ? 1 : 0
                        color: act.on ? Theme.inkPrimary : Theme.ink
                    }
                    StateLayer {
                        onEntered: v.sel = act.index
                        onClicked: v.run(act.index)
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: act.modelData.label; size: 12
                    color: act.on ? Theme.ink : Theme.inkDim
                }
            }
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Left || e.key === Qt.Key_H) v.sel = (v.sel + 4) % 5;
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab) v.sel = (v.sel + 1) % 5;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) v.run(v.sel);
            else if (e.key === Qt.Key_Escape) v.isle.close();
            else return;
            e.accepted = true;
        }
    }
}
