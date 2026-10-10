import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// you: your picture (~/.face), user@host, how long it's been up, the weather
// in a word, and lock, settings and power at hand
Card {
    id: c
    property string layout: "card"
    property var settings: ({})
    property string itemId
    readonly property bool compact: layout === "compact"
    width: compact ? 300 : 300
    height: compact ? 76 : 176

    readonly property string user: Quickshell.env("USER")
    property string host: ""
    property real uptime: 0
    FileView { id: hostFile; path: "/etc/hostname"; onLoaded: c.host = text().trim() }
    FileView { id: up; path: "/proc/uptime"; onLoaded: c.uptime = parseFloat(text()) }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: up.reload() }
    readonly property string upFor: {
        const m = Math.floor(uptime / 60), h = Math.floor(m / 60), d = Math.floor(h / 24);
        return d > 0 ? d + "d " + (h % 24) + "h" : h > 0 ? h + "h " + (m % 60) + "m" : m + "m";
    }
    // ~/.face, else the picture AccountsService keeps, else a letter
    property string face: ""
    Process {
        running: true
        command: ["sh", "-c", "for f in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$USER\"; do [ -s \"$f\" ] && { echo \"$f\"; break; }; done"]
        stdout: StdioCollector { onStreamFinished: c.face = text.trim() }
    }

    component Face: ClippingRectangle {
        id: face
        radius: width / 2
        color: Theme.primaryContainer
        Txt { anchors.centerIn: parent; visible: pic.status !== Image.Ready; text: c.user.charAt(0).toUpperCase(); size: face.width * 0.42; weight: Font.DemiBold; color: Theme.inkPrimaryContainer }
        Image {
            id: pic
            anchors.fill: parent
            source: c.face ? "file://" + c.face : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(face.width * 2, face.height * 2)
            asynchronous: true
        }
    }
    component Round: IconButton { size: 36; filled: true }

    // card
    Face { visible: !c.compact; x: 20; y: 20; width: 64; height: 64 }
    Column {
        visible: !c.compact
        x: 98; y: 26; width: parent.width - 118
        spacing: 2
        Txt { width: parent.width; text: c.user + "@" + c.host; size: 15; weight: Font.DemiBold }
        Txt { width: parent.width; text: "Up " + c.upFor; size: 12; color: Theme.inkDim }
        Row {
            visible: Weather.ready
            spacing: 4
            Icon { name: Weather.icon(Weather.code, Weather.day); size: 15; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
            Txt { text: Weather.words(Weather.code).toLowerCase() + " today"; size: 12; color: Theme.inkDim }
        }
    }
    Row {
        visible: !c.compact
        x: 20; anchors { bottom: parent.bottom; bottomMargin: 18 }
        spacing: 8
        Rectangle {
            width: 120; height: 36; radius: 18
            color: Theme.primary
            Row {
                anchors.centerIn: parent; spacing: 6
                Icon { name: "lock"; size: 17; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
                Txt { text: "Lock"; size: 13; weight: Font.Medium; color: Theme.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
            }
            StateLayer { tint: Theme.inkPrimary; onClicked: Quickshell.execDetached(["yoru-lock"]) }
        }
        Round { icon: "settings"; onClicked: Quickshell.execDetached(["qs", "-n", "-p", Quickshell.shellDir + "/settings.qml"]) }
        Round { icon: "power_settings_new"; onClicked: Desk.island("power") }
    }

    // compact: one row
    Face { visible: c.compact; x: 14; anchors.verticalCenter: parent.verticalCenter; width: 48; height: 48 }
    Column {
        visible: c.compact
        x: 74; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 74 - 92
        Txt { width: parent.width; text: c.user; size: 14; weight: Font.DemiBold }
        Txt { width: parent.width; text: "Up " + c.upFor; size: 12; color: Theme.inkDim }
    }
    Row {
        visible: c.compact
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 6
        Round { icon: "lock"; onClicked: Quickshell.execDetached(["yoru-lock"]) }
        Round { icon: "power_settings_new"; onClicked: Desk.island("power") }
    }
}
