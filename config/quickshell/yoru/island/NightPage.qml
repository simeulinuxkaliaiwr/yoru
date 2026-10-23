import QtQuick
import qs
import qs.parts
import qs.phone

// the control centre's night light: how warm, and whether it comes on by itself, with the
// sun where the weather is or between two hours
Item {
    id: np
    required property var host
    readonly property var c: Config.o.night
    implicitHeight: head.height + body.implicitHeight + 16

    PanelHead {
        id: head
        phone: np.host
        title: "Night light"
        on: Status.night
        onToggled: Status.toggleNight()
    }

    // an hour, half an hour at a time
    function shift(hhmm, by) {
        const [h, m] = String(hhmm).split(":").map(Number);
        const t = (((h || 0) * 60 + (m || 0) + by) % 1440 + 1440) % 1440;
        return String(Math.floor(t / 60)).padStart(2, "0") + ":" + String(t % 60).padStart(2, "0");
    }
    component Hour: Rectangle {
        id: hr
        property string label
        property string value
        signal moved(int by)
        width: (body.width - 8) / 2; height: 64
        radius: Theme.r(22)
        color: Theme.surfaceMid
        Column {
            x: 16; anchors.verticalCenter: parent.verticalCenter
            Txt { text: hr.label; size: 11; color: Theme.inkDim }
            Txt { text: hr.value; size: 20; weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }
        Row {
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            IconButton { icon: "remove"; size: 30; onClicked: hr.moved(-30) }
            IconButton { icon: "add"; size: 30; onClicked: hr.moved(30) }
        }
    }

    Column {
        id: body
        anchors { top: head.bottom; topMargin: 10; left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
        spacing: 12

        // warmth: right is warmer; the track shows the colour it turns the screen
        Item {
            width: parent.width; height: 64
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 6; radius: 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#fff4e5" }
                    GradientStop { position: 0.55; color: "#ffc477" }
                    GradientStop { position: 1; color: "#ff8f2e" }
                }
            }
            Txt { x: 6; text: "Warmth"; size: 12; weight: Font.DemiBold; color: Theme.inkDim }
            Txt {
                anchors.right: parent.right; rightPadding: 6
                text: Status.warmth + " K"; size: 12; weight: Font.DemiBold; color: Theme.inkDim
                font.features: { "tnum": 1 }
            }
            Slider {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 12 }
                h: 34
                icon: "nightlight"
                value: (6000 - Status.warmth) / 3500
                onMoved: x => np.c.warmth = Math.round((6000 - x * 3500) / 100) * 100
            }
        }

        Txt { x: 6; text: "Comes on by itself"; size: 12; weight: Font.DemiBold; color: Theme.inkDim }
        Flow {
            width: parent.width
            spacing: 8
            Pill { icon: "do_not_disturb_on"; label: "No"; on: np.c.auto === "off"; onClicked: np.c.auto = "off" }
            Pill { icon: "wb_twilight"; label: "Sunset to sunrise"; on: np.c.auto === "sun"; onClicked: np.c.auto = "sun" }
            Pill { icon: "schedule"; label: "Hours"; on: np.c.auto === "hours"; onClicked: np.c.auto = "hours" }
        }
        Txt {
            visible: np.c.auto === "sun"
            x: 6; width: parent.width - 12
            text: Weather.located ? "Tonight from " + Status.nightFrom + " to " + Status.nightTo + ", by the sun in " + (Weather.place || "your city")
                                  : "Until the weather knows where you are: " + Status.nightFrom + " to " + Status.nightTo
            size: 12; color: Theme.inkDim; wrapMode: Text.Wrap
        }
        Row {
            visible: np.c.auto === "hours"
            spacing: 8
            Hour { label: "From"; value: np.c.from; onMoved: by => np.c.from = np.shift(np.c.from, by) }
            Hour { label: "To"; value: np.c.to; onMoved: by => np.c.to = np.shift(np.c.to, by) }
        }
    }
}
