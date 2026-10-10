import QtQuick
import qs
import qs.parts

// a note: on a sticky sheet, on ruled paper, or just the words
Card {
    id: c
    property string layout: "sticky"
    property var settings: ({})
    property string itemId
    readonly property bool sticky: layout === "sticky"
    readonly property color ink: sticky ? Theme.inkTertiaryContainer : Theme.ink
    width: 300
    height: Math.max(150, Math.min(460, body.y + body.implicitHeight + 22))

    // sticky: the coloured sheet, a fold at its corner
    Rectangle {
        visible: c.sticky
        anchors { fill: parent; margins: 6 }
        radius: Math.max(0, c.radius - 6)
        color: Theme.alpha(Theme.tertiaryContainer, 0.95)
        Rectangle {
            anchors { right: parent.right; bottom: parent.bottom }
            width: 30; height: 30; radius: 6
            color: Theme.alpha(Theme.inkTertiaryContainer, 0.12)
        }
    }
    // paper: ruled lines and a margin
    Repeater {
        model: c.layout === "paper" ? Math.max(0, Math.floor((c.height - 56) / 26)) : 0
        Rectangle {
            required property int index
            x: 18; width: c.width - 36; height: 1
            y: 56 + 22 + index * 26
            color: Theme.alpha(Theme.primary, 0.18)
        }
    }
    Rectangle {
        visible: c.layout === "paper"
        x: 42; y: 12; width: 1.5; height: c.height - 24
        color: Theme.alpha(Theme.tertiary, 0.35)
    }

    Txt {
        id: head
        x: c.layout === "paper" ? 52 : 22; y: 18
        width: parent.width - x - 22
        text: c.settings.title ?? ""
        visible: text !== ""
        size: 15; weight: Font.DemiBold
        color: c.ink
    }
    Text {
        id: body
        x: head.x; width: head.width
        y: head.visible ? 48 : 20
        text: c.settings.text ?? ""
        wrapMode: Text.Wrap
        color: c.ink
        lineHeightMode: Text.FixedHeight
        lineHeight: 26
        font.family: c.layout === "paper" ? "Instrument Serif" : Theme.sans
        font.pixelSize: c.layout === "paper" ? 19 : 14
        maximumLineCount: 16
        elide: Text.ElideRight
    }
}
