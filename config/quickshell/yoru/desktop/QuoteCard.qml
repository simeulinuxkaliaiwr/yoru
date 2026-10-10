import Quickshell
import QtQuick
import qs
import qs.parts

// a line to keep in view: yours, or a different old one each day
//   bubble: a small speech bubble · serif: big and italic, no fuss · plain: the words and who said them
Card {
    id: c
    property string layout: "bubble"
    property var settings: ({})
    property string itemId
    readonly property bool bubble: layout === "bubble"

    // old enough to belong to everyone
    readonly property var daily: [
        ["The night is long that never finds the day.", "Shakespeare"],
        ["What we achieve inwardly will change outer reality.", "Plutarch"],
        ["Waste no more time arguing what a good person should be. Be one.", "Marcus Aurelius"],
        ["A journey of a thousand miles begins with a single step.", "Lao Tzu"],
        ["Luck is what happens when preparation meets opportunity.", "Seneca"],
        ["Nature does not hurry, yet everything is accomplished.", "Lao Tzu"],
        ["It does not matter how slowly you go as long as you do not stop.", "Confucius"],
        ["The best way out is always through.", "Robert Frost"],
        ["Well begun is half done.", "Aristotle"],
        ["Hope is the thing with feathers that perches in the soul.", "Emily Dickinson"],
        ["The snow goose need not bathe to make itself white.", "Lao Tzu"],
        ["Keep your face always toward the sunshine.", "Walt Whitman"],
        ["He who has a why to live can bear almost any how.", "Nietzsche"],
        ["Very little is needed to make a happy life.", "Marcus Aurelius"],
        ["We suffer more often in imagination than in reality.", "Seneca"],
        ["Silence is a source of great strength.", "Lao Tzu"],
        ["Dwell on the beauty of life. Watch the stars, and see yourself running with them.", "Marcus Aurelius"],
        ["Everything has beauty, but not everyone sees it.", "Confucius"],
        ["To see a world in a grain of sand, and a heaven in a wild flower.", "William Blake"],
        ["The future starts today, not tomorrow.", "Pope John Paul II"],
        ["Do what you can, with what you have, where you are.", "Theodore Roosevelt"],
        ["Fall seven times, stand up eight.", "Japanese proverb"],
        ["Even monkeys fall from trees.", "Japanese proverb"],
        ["After the rain, the ground hardens.", "Japanese proverb"],
        ["The reverse side also has a reverse side.", "Japanese proverb"],
        ["Tomorrow's wind will blow tomorrow.", "Japanese proverb"],
        ["Snow falls on the just and the unjust alike.", "Proverb"],
        ["Be like water.", "after Lao Tzu"],
    ]
    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property int dayOfYear: Math.floor((clock.date - new Date(clock.date.getFullYear(), 0, 0)) / 86400000)
    readonly property bool useDaily: settings.daily ?? true
    readonly property var pick: useDaily || !settings.text ? daily[dayOfYear % daily.length] : [settings.text, settings.author ?? ""]

    width: bubble ? Math.min(420, words.implicitWidth + 64) : layout === "serif" ? 420 : 340
    height: bubble ? Math.max(48, words.implicitHeight + 24) : words.y + words.implicitHeight + (who.visible ? who.implicitHeight + 30 : 22)
    radius: bubble ? Math.min(height / 2, 24) : Config.o.desktop.widgetRadius

    Icon {
        visible: c.layout !== "serif"
        x: c.bubble ? 14 : 20; y: c.bubble ? (c.height - height) / 2 : 18
        name: "format_quote"; size: c.bubble ? 20 : 28; fill: 1
        color: Theme.primary
    }
    Text {
        id: words
        x: c.bubble ? 42 : 24
        y: c.bubble ? 12 : c.layout === "serif" ? 22 : 52
        width: c.bubble ? Math.min(implicitWidth, 420 - 64) : c.width - 48
        text: c.layout === "serif" ? "“" + c.pick[0] + "”" : c.pick[0]
        wrapMode: Text.Wrap
        color: Theme.ink
        font.family: c.layout === "serif" ? "Instrument Serif" : Theme.sans
        font.italic: c.layout === "serif"
        font.pixelSize: c.layout === "serif" ? 30 : c.bubble ? 14 : 17
        font.weight: c.bubble ? Font.Medium : Font.Normal
        lineHeight: c.layout === "serif" ? 1.05 : 1.15
    }
    Txt {
        id: who
        visible: !c.bubble && c.pick[1] !== ""
        anchors { top: words.bottom; topMargin: 12; left: words.left }
        text: "— " + c.pick[1]
        size: 13; color: Theme.inkDim
    }
}
