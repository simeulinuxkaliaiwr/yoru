import QtQuick
import qs
import qs.parts

// a text field that saves when you press Enter or leave it
Rectangle {
    id: f
    property string text
    property string placeholder: ""
    signal edited(string text)
    width: 260; height: 40; radius: Theme.r(20)
    color: Theme.surfaceMid
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.primary : Theme.outlineVariant
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        verticalAlignment: TextInput.AlignVCenter
        text: f.text
        color: Theme.ink
        font { family: Theme.sans; pixelSize: 14 }
        clip: true
        onEditingFinished: if (text !== f.text) f.edited(text)
        Txt { anchors.verticalCenter: parent.verticalCenter; visible: input.text === ""; text: f.placeholder; color: Theme.outline; size: 14 }
    }
}
