import Quickshell
import QtQuick
import qs
import qs.parts

Column {
    spacing: 14

    Section {
        icon: "bedtime"; title: "yoru"
        Column {
            x: 10
            spacing: 4
            Txt { text: "夜"; size: 64; weight: Font.Light; color: Theme.primary; font.family: "Noto Sans CJK JP" }
            Txt { text: "the night rice for aro"; size: 14; color: Theme.inkDim }
            Item { width: 1; height: 10 }
        }
        SetRow {
            icon: "swap_horiz"; label: "Back to kon"; hint: "mod+ctrl+r switches either way"
            Btn { label: "Switch"; tonal: true; onClicked: Quickshell.execDetached(["rice", "kon"]) }
        }
        SetRow {
            icon: "description"; label: "Config file"; hint: Config.path
            Btn { label: "Copy path"; tonal: true; onClicked: Quickshell.execDetached(["wl-copy", Config.path]) }
        }
    }

    Section {
        icon: "keyboard"; title: "Keys"
        Repeater {
            model: [
                ["mod+a", "Launcher"], ["mod+v", "Clipboard"], ["mod+x", "Control centre"], ["mod+m", "Player"],
                ["mod+w", "Wallpapers"], ["mod+shift+w", "Next wallpaper"], ["mod+i", "Settings"],
                ["mod+escape", "Lock"], ["mod+shift+e", "Power"], ["Print, mod+Print", "Screenshot, area"], ["mod+ctrl+r", "Switch rice"]
            ]
            Item {
                required property var modelData
                width: parent.width; height: 36
                Rectangle {
                    x: 10; anchors.verticalCenter: parent.verticalCenter
                    width: k.implicitWidth + 20; height: 28; radius: 8
                    color: Theme.surfaceHigh
                    Txt { id: k; anchors.centerIn: parent; text: parent.parent.modelData[0]; size: 12; font.family: Theme.mono }
                }
                Txt { x: 200; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData[1]; size: 13; color: Theme.inkDim }
            }
        }
        Item { width: 1; height: 8 }
    }
}
