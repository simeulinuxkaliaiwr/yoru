import QtQuick
import qs
import qs.parts

// a short list of things to do, ticked off right on the desktop (they're
// written in edit mode):
//   list: a pill each, in the palette's colours · checks: a plain checklist ·
//   progress: how much is done, and what's next
Card {
    id: c
    property string layout: "list"
    property var settings: ({})
    property string itemId
    readonly property var items: (settings.items ?? []).filter(x => x && x.text)
    readonly property int done: items.filter(x => x.done).length
    readonly property var next: items.find(x => !x.done) ?? null
    width: 300
    height: layout === "progress" ? 150 : 60 + Math.max(1, items.length) * (layout === "list" ? 54 : 34) + 8

    function toggle(i) {
        if (!itemId) return;
        const all = (settings.items ?? []).slice(), x = items[i], at = all.indexOf(x);
        if (at < 0) return;
        all[at] = Object.assign({}, x, { done: !x.done });
        Desk.setting(itemId, "items", all);
    }

    Row {
        x: 20; y: 16; spacing: 8
        Txt { text: c.settings.title || "To-do"; size: 16; weight: Font.DemiBold }
        Txt { visible: c.items.length > 0; text: c.done + "/" + c.items.length; size: 12; color: Theme.inkDim; anchors.baseline: parent.children[0].baseline }
    }
    Txt { visible: !c.items.length && c.layout !== "progress"; x: 20; y: 54; text: "Nothing to do. Add some in edit mode"; size: 13; color: Theme.inkDim }

    // a round tick box
    component Tick: Rectangle {
        property bool on
        property color tone: Theme.primary
        width: 22; height: 22; radius: Theme.r(11)
        color: on ? tone : "transparent"
        border.width: on ? 0 : 2
        border.color: Theme.alpha(Theme.ink, 0.55)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Icon { anchors.centerIn: parent; visible: parent.on; name: "check"; size: 16; weight: 700; color: Theme.surfaceLowest }
    }

    // list: pills
    Column {
        visible: c.layout === "list"
        x: 14; y: 52; width: parent.width - 28
        spacing: 8
        Repeater {
            model: c.layout === "list" ? c.items : []
            Rectangle {
                required property var modelData
                required property int index
                readonly property var tones: [[Theme.primaryContainer, Theme.inkPrimaryContainer], [Theme.secondaryContainer, Theme.inkSecondaryContainer],
                                              [Theme.tertiaryContainer, Theme.inkTertiaryContainer]]
                readonly property var tone: tones[index % 3]
                width: parent.width; height: 46; radius: Theme.r(23)
                color: tone[0]
                opacity: modelData.done ? 0.55 : 1
                Tick { x: 12; anchors.verticalCenter: parent.verticalCenter; on: modelData.done; tone: parent.tone[1] }
                Txt {
                    x: 44; width: parent.width - 56; anchors.verticalCenter: parent.verticalCenter
                    text: modelData.text; size: 13; color: parent.tone[1]
                    font.strikeout: modelData.done
                }
                StateLayer { tint: parent.tone[1]; onClicked: c.toggle(index) }
            }
        }
    }
    // checks: a plain list
    Column {
        visible: c.layout === "checks"
        x: 16; y: 52; width: parent.width - 32
        spacing: 2
        Repeater {
            model: c.layout === "checks" ? c.items : []
            Item {
                required property var modelData
                required property int index
                width: parent.width; height: 32
                Tick { x: 2; anchors.verticalCenter: parent.verticalCenter; on: modelData.done; scale: 0.85 }
                Txt {
                    x: 32; width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter
                    text: modelData.text; size: 13
                    color: modelData.done ? Theme.inkDim : Theme.ink
                    font.strikeout: modelData.done
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: c.toggle(index) }
            }
        }
    }
    // progress: a ring and the next thing
    Ring {
        visible: c.layout === "progress"
        x: 18; y: 50
        value: c.items.length ? c.done / c.items.length : 0
        icon: "checklist"; label: ""; text: c.items.length ? Math.round(c.done / c.items.length * 100) + "%" : "–"
    }
    Column {
        visible: c.layout === "progress"
        x: 100; y: 58; width: parent.width - 118
        spacing: 2
        Txt { text: c.next ? "Next" : "All done"; size: 11; color: Theme.inkDim }
        Txt { width: parent.width; text: c.next ? c.next.text : "Nothing left on the list"; size: 14; weight: Font.Medium; wrapMode: Text.Wrap; maximumLineCount: 2 }
        Item { width: 1; height: 4 }
        Rectangle {
            visible: !!c.next
            width: 96; height: 30; radius: Theme.r(15)
            color: Theme.secondaryContainer
            Txt { anchors.centerIn: parent; text: "Done"; size: 12; weight: Font.Medium; color: Theme.inkSecondaryContainer }
            StateLayer { tint: Theme.inkSecondaryContainer; onClicked: c.toggle(c.items.indexOf(c.next)) }
        }
    }
}
