import Quickshell
import QtQuick
import QtQuick.Shapes
import qs
import qs.parts

// the day: a greeting, the weather now and through the next hours, the month, the focus
// timer while it runs, and the notifications by app (a click opens one, as its toast would)
Item {
    id: tp
    required property var phone
    property bool live: false
    property bool compact: false
    readonly property int pad: compact ? 12 : 18
    property int offset: 0                  // months away from this one
    property var open: ({})                 // app → shows all of its notifications

    SystemClock { id: clock; precision: SystemClock.Minutes }
    onLiveChanged: {
        if (live) Notifs.unseen = 0;
        else offset = 0;
    }

    function key(e) {
        if (e.key === Qt.Key_Down || e.key === Qt.Key_Up) {
            const to = flick.contentY + (e.key === Qt.Key_Down ? 90 : -90);
            flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), to));
            return true;
        }
        return false;
    }

    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    }
    function ago(t) {
        const m = Math.floor((clock.date.getTime() - t) / 60000);
        if (m < 1) return "now";
        if (m < 60) return m + " min";
        const h = Math.floor(m / 60);
        return h < 24 ? h + " h" : Math.floor(h / 24) + " d";
    }
    // the month on show, Monday first
    readonly property date first: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)
    readonly property var days: {
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) out.push(new Date(first.getFullYear(), first.getMonth(), 1 - lead + i));
        return out;
    }
    readonly property int weeks: Math.ceil(((first.getDay() + 6) % 7 + new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()) / 7)

    component Card: Rectangle {
        width: parent ? parent.width : 0
        radius: Theme.r(tp.compact ? 20 : 26)
        color: Theme.alpha(Theme.surfaceHigh, 0.72)
        border.width: Theme.border
        border.color: Theme.borderColour
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight + 20
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Behavior on contentY { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

        Column {
            id: col
            x: tp.pad
            y: tp.compact ? 6 : 12
            width: tp.width - 2 * tp.pad
            spacing: tp.compact ? 8 : 12

            // hello
            Column {
                leftPadding: 4
                Txt { text: tp.greeting + ", " + Quickshell.env("USER"); size: tp.compact ? 16 : 20; weight: Font.DemiBold }
                Txt { text: Qt.formatDate(clock.date, "dddd, d MMMM"); size: tp.compact ? 11 : 13; color: Theme.inkDim }
            }

            // the weather
            Card {
                visible: Weather.ready
                height: wcol.implicitHeight + (tp.compact ? 18 : 26)
                Column {
                    id: wcol
                    x: tp.compact ? 12 : 16
                    y: tp.compact ? 9 : 13
                    width: parent.width - 2 * x
                    spacing: tp.compact ? 6 : 10
                    Item {
                        width: parent.width
                        height: tp.compact ? 38 : 50
                        Icon {
                            id: wicon
                            anchors.verticalCenter: parent.verticalCenter
                            name: Weather.icon(Weather.code, Weather.day)
                            size: tp.compact ? 30 : 40; fill: 1; color: Theme.primary
                        }
                        Txt {
                            id: wtemp
                            anchors { left: wicon.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            text: Math.round(Weather.temp) + "°"
                            size: tp.compact ? 28 : 36; weight: Font.Light
                        }
                        Column {
                            anchors { left: wtemp.right; leftMargin: 10; right: parent.right; verticalCenter: parent.verticalCenter }
                            Txt { width: parent.width; text: Weather.words(Weather.code); size: tp.compact ? 12 : 13; weight: Font.DemiBold }
                            Txt {
                                width: parent.width
                                text: (Weather.days.length ? Math.round(Weather.days[0].max) + "° / " + Math.round(Weather.days[0].min) + "°  ·  " : "") + Weather.place
                                size: 11; color: Theme.inkDim
                            }
                        }
                    }
                    // the next hours
                    ListView {
                        width: parent.width
                        height: tp.compact ? 54 : 62
                        orientation: ListView.Horizontal
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 2
                        model: Weather.hours.slice(0, 12)
                        delegate: Column {
                            required property var modelData
                            required property int index
                            width: tp.compact ? 38 : 46
                            spacing: 3
                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: index === 0 ? "Now" : modelData.time.slice(11, 13)
                                size: 10; color: index === 0 ? Theme.primary : Theme.inkDim
                                weight: index === 0 ? Font.DemiBold : Font.Normal
                            }
                            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(modelData.code, true); size: tp.compact ? 16 : 20; color: Theme.ink }
                            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(modelData.temp) + "°"; size: 11; weight: Font.Medium; font.features: { "tnum": 1 } }
                        }
                    }
                }
            }

            // the month: scroll or the arrows for others
            Card {
                height: mcol.implicitHeight + (tp.compact ? 14 : 22)
                Column {
                    id: mcol
                    x: tp.compact ? 8 : 12
                    y: tp.compact ? 7 : 11
                    width: parent.width - 2 * x
                    Item {
                        width: parent.width; height: tp.compact ? 28 : 34
                        Txt {
                            x: 6; anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDate(tp.first, "MMMM") + (tp.first.getFullYear() !== clock.date.getFullYear() ? " " + tp.first.getFullYear() : "")
                            size: tp.compact ? 13 : 15; weight: Font.DemiBold
                        }
                        Row {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            IconButton { size: tp.compact ? 24 : 30; icon: "chevron_left"; onClicked: tp.offset-- }
                            IconButton { size: tp.compact ? 24 : 30; icon: "today"; visible: tp.offset !== 0; onClicked: tp.offset = 0 }
                            IconButton { size: tp.compact ? 24 : 30; icon: "chevron_right"; onClicked: tp.offset++ }
                        }
                    }
                    Grid {
                        columns: 7
                        readonly property real cw: mcol.width / 7
                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            Txt {
                                required property string modelData
                                required property int index
                                width: parent.cw; height: tp.compact ? 18 : 22
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData; size: 10; weight: Font.DemiBold
                                color: index >= 5 ? Theme.tertiary : Theme.outline
                            }
                        }
                        Repeater {
                            model: tp.days.slice(0, tp.weeks * 7)
                            Item {
                                required property var modelData
                                readonly property bool inMonth: modelData.getMonth() === tp.first.getMonth()
                                readonly property bool today: modelData.toDateString() === clock.date.toDateString()
                                width: parent.cw; height: tp.compact ? 24 : 30
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height) - 2; height: width
                                    radius: Theme.r(width / 2)
                                    color: parent.today ? Theme.primary : "transparent"
                                }
                                Txt {
                                    anchors.centerIn: parent
                                    text: parent.modelData.getDate()
                                    size: tp.compact ? 11 : 12
                                    weight: parent.today ? Font.Bold : Font.Normal
                                    color: parent.today ? Theme.inkPrimary : parent.inMonth ? Theme.ink : Theme.alpha(Theme.inkDim, 0.35)
                                    font.features: { "tnum": 1 }
                                }
                            }
                        }
                    }
                }
                WheelHandler { onWheel: e => tp.offset += e.angleDelta.y > 0 ? -1 : 1 }
            }

            // the focus timer, while it runs
            Card {
                visible: Focus.active
                height: tp.compact ? 52 : 62
                Shape {
                    id: ring
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 30
                    preferredRendererType: Shape.CurveRenderer
                    readonly property color tone: Focus.phase === "break" ? Theme.tertiary : Theme.primary
                    ShapePath {
                        strokeColor: Theme.surfaceHighest; strokeWidth: 4; fillColor: "transparent"
                        PathAngleArc { centerX: 15; centerY: 15; radiusX: 12; radiusY: 12; startAngle: 0; sweepAngle: 360 }
                    }
                    ShapePath {
                        strokeColor: ring.tone; strokeWidth: 4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 15; centerY: 15; radiusX: 12; radiusY: 12; startAngle: -90; sweepAngle: Math.max(1, 360 * Focus.progress) }
                    }
                }
                Column {
                    anchors { left: ring.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    Txt { text: Focus.phase === "break" ? "On a break" : "Focusing"; size: 13; weight: Font.DemiBold }
                    Txt { text: Focus.clock(Focus.left) + " left" + (Focus.today > 0 ? "  ·  " + Focus.today + " today" : ""); size: 11; color: Theme.inkDim; font.features: { "tnum": 1 } }
                }
                IconButton {
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    icon: "stop"; filled: true; size: 34
                    onClicked: Focus.stop()
                }
            }

            // the notifications
            Item {
                width: parent.width; height: 26
                Txt { x: 4; anchors.verticalCenter: parent.verticalCenter; text: "Notifications"; size: 13; weight: Font.DemiBold; color: Theme.inkDim }
                Txt {
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    visible: Notifs.count > 0
                    text: "Clear all"; size: 12; weight: Font.Medium; color: Theme.primary
                    MouseArea { anchors { fill: parent; margins: -6 } cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clear() }
                }
            }
            Card {
                visible: Notifs.count === 0
                height: 74
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bedtime"; size: 24; color: Theme.outline }
                    Txt { text: "All quiet tonight"; size: 12; color: Theme.outline }
                }
            }
            Repeater {
                model: Notifs.groups
                Card {
                    id: group
                    required property var modelData
                    readonly property bool all: tp.open[modelData.app] === true
                    readonly property var shown: all ? modelData.items : modelData.items.slice(0, 2)
                    height: inner.implicitHeight + 14
                    Column {
                        id: inner
                        x: 7; y: 7
                        width: parent.width - 14
                        spacing: 3
                        Item {
                            width: parent.width; height: 28
                            Image {
                                id: gimg
                                x: 6; anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18
                                source: group.modelData.icon
                                sourceSize: Qt.size(36, 36)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Icon { x: 6; anchors.verticalCenter: parent.verticalCenter; visible: !gimg.visible; name: "notifications"; size: 16; color: Theme.inkDim }
                            Txt {
                                anchors { left: parent.left; leftMargin: 32; right: wipeApp.left; verticalCenter: parent.verticalCenter }
                                text: group.modelData.app + (group.modelData.items.length > 1 ? "  ·  " + group.modelData.items.length : "")
                                size: 11; weight: Font.DemiBold; color: Theme.inkDim
                            }
                            IconButton { id: wipeApp; anchors { right: parent.right; verticalCenter: parent.verticalCenter } icon: "clear_all"; size: 26; onClicked: Notifs.forgetApp(group.modelData.app) }
                        }
                        Repeater {
                            model: group.shown
                            Rectangle {
                                id: note
                                required property var modelData
                                width: inner.width
                                height: Math.max(44, body.implicitHeight + 14)
                                radius: Theme.r(14)
                                color: Theme.alpha(Theme.surfaceHighest, 0.7)
                                readonly property var def: Notifs.live[modelData.key]?.actions?.find(a => a.identifier === "default") ?? null
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: note.def !== null
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { note.def.invoke(); tp.phone.close(); }
                                }
                                Column {
                                    id: body
                                    anchors { left: parent.left; leftMargin: 11; right: when.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                    spacing: 1
                                    Txt { width: parent.width; text: note.modelData.summary; size: 12; weight: Font.DemiBold }
                                    Txt {
                                        width: parent.width; visible: text !== ""
                                        text: note.modelData.body; textFormat: Text.StyledText
                                        wrapMode: Text.Wrap; maximumLineCount: 3; size: 11; color: Theme.inkDim
                                    }
                                }
                                Txt {
                                    id: when
                                    anchors { right: cross.left; rightMargin: 2; top: parent.top; topMargin: 9 }
                                    text: tp.ago(note.modelData.time); size: 10; color: Theme.outline
                                }
                                IconButton {
                                    id: cross
                                    anchors { right: parent.right; rightMargin: 3; top: parent.top; topMargin: 3 }
                                    icon: "close"; size: 24
                                    onClicked: Notifs.forget(note.modelData.key)
                                }
                            }
                        }
                        Txt {
                            visible: group.modelData.items.length > 2
                            x: 10; height: 22; verticalAlignment: Text.AlignVCenter
                            text: group.all ? "Show less" : (group.modelData.items.length - 2) + " more"
                            size: 11; weight: Font.Medium; color: Theme.primary
                            MouseArea {
                                anchors { fill: parent; margins: -6 }
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { const o = Object.assign({}, tp.open); o[group.modelData.app] = !group.all; tp.open = o; }
                            }
                        }
                    }
                }
            }
        }
    }
}
