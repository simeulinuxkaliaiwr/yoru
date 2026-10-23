import Quickshell
import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// a notification (or a screenshot) dropping out of the island
Item {
    id: v
    required property var isle
    readonly property var t: isle?.toast ?? null            // { notif } or { icon, title, body, image }
    readonly property var n: t?.notif ?? null
    readonly property string img: n ? Notifs.image(n) : (t?.image ?? "")
    readonly property bool shot: !!t?.shot
    readonly property bool hovered: hover.hovered

    implicitWidth: 440
    implicitHeight: Math.max(76, col.implicitHeight + 28)

    HoverHandler { id: hover }

    ClippingRectangle {
        id: pic
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        width: v.shot ? 112 : 44
        height: v.shot ? 63 : 44
        radius: v.shot ? 10 : 14
        color: v.t?.swatch ?? Theme.surfaceHigh
        Image {
            anchors.fill: parent
            source: v.img
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(224, 126)
            asynchronous: true
            visible: status === Image.Ready
        }
        Icon {
            anchors.centerIn: parent
            visible: v.img === "" && !v.t?.swatch
            name: v.t?.icon ?? "notifications"
            size: 22; fill: 1
            color: Theme.primary
        }
    }

    Column {
        id: col
        anchors { left: pic.right; leftMargin: 14; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
        spacing: 3
        Txt {
            width: parent.width
            text: v.n ? (v.n.appName || "notification") : (v.t?.app ?? "yoru")
            size: 11; weight: Font.Medium
            color: Theme.primary
        }
        Txt {
            width: parent.width
            text: v.n ? v.n.summary : (v.t?.title ?? "")
            size: 14; weight: Font.DemiBold
        }
        Txt {
            width: parent.width
            visible: text !== ""
            text: v.n ? v.n.body : (v.t?.body ?? "")
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            size: 12
            color: Theme.inkDim
        }
        Row {
            visible: (v.n?.actions?.length ?? 0) > 0
            spacing: 6
            topPadding: 6
            Repeater {
                model: v.n?.actions ?? []
                Rectangle {
                    required property var modelData
                    height: 28
                    width: label.implicitWidth + 24
                    radius: Theme.r(14)
                    color: Theme.secondaryContainer
                    Txt { id: label; anchors.centerIn: parent; text: parent.modelData.text; size: 12; weight: Font.Medium; color: Theme.inkSecondaryContainer }
                    StateLayer { onClicked: { parent.modelData.invoke(); v.isle.dropToast(); } }
                }
            }
        }
    }

    // a swipe up or sideways puts it away: it follows the finger, and goes if it went far enough
    transform: Translate {
        x: swipe.active ? swipe.activeTranslation.x * 0.7 : 0
        y: swipe.active ? Math.min(0, swipe.activeTranslation.y) * 0.7 : 0
        Behavior on x { enabled: !swipe.active; NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !swipe.active; NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
    }
    opacity: swipe.active ? Math.max(0.2, 1 - Math.max(Math.abs(swipe.activeTranslation.x) / 220, -swipe.activeTranslation.y / 90)) : 1
    DragHandler {
        id: swipe
        target: null
        // how far it went, kept: the handler's own is gone by the time it lets go
        property vector2d last
        onActiveTranslationChanged: if (active) last = activeTranslation
        onActiveChanged: {
            if (active) last = Qt.vector2d(0, 0);
            else if (last.y < -36 || Math.abs(last.x) > 90) v.isle.dropToast();
        }
    }

    // a click opens it (the default action), a right-click puts it away
    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (p, button) => {
            if (button === Qt.LeftButton) {
                const def = v.n?.actions?.find(a => a.identifier === "default");
                if (def) def.invoke();
                else if (v.shot) Quickshell.execDetached(["xdg-open", v.img]);
                else if (v.t?.open) { const isle = v.isle, m = v.t.open; isle.dropToast(); isle.open(m); return; }
            }
            v.isle.dropToast();
        }
    }
}
