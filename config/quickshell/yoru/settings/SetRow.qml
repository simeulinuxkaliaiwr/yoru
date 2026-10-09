import QtQuick
import qs
import qs.parts

// one settings line: icon, label and a hint on the left, a control on the right
Item {
    id: row
    property string icon: ""
    property string label
    property string hint: ""
    default property alias control: slot.data
    width: parent ? parent.width : 500
    height: Math.max(56, text.implicitHeight + 20)

    Icon { id: ic; x: 10; anchors.verticalCenter: parent.verticalCenter; name: row.icon; size: 20; color: Theme.inkDim; visible: row.icon !== "" }
    Column {
        id: text
        anchors { left: row.icon !== "" ? ic.right : parent.left; leftMargin: row.icon !== "" ? 14 : 10; right: slot.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        Txt { width: parent.width; text: row.label; size: 14 }
        Txt { width: parent.width; visible: row.hint !== ""; text: row.hint; size: 12; color: Theme.inkDim; wrapMode: Text.Wrap; elide: Text.ElideNone }
    }
    Item {
        id: slot
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        width: childrenRect.width; height: childrenRect.height
    }
}
