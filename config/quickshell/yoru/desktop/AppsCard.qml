import Quickshell
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// apps to start from the desktop, chosen in edit mode (by desktop entry id):
//   dock: a row of icons that swell under the pointer · grid: tiles with names
Card {
    id: c
    property string layout: "dock"
    property var settings: ({})
    property string itemId
    readonly property var apps: (settings.apps ?? []).map(id => DesktopEntries.applications.values.find(e => e.id === id || e.id === id + ".desktop")).filter(e => !!e)
    readonly property bool dock: layout === "dock"
    readonly property int cols: 3
    width: dock ? Math.max(1, apps.length) * 60 + 24 : cols * 92 + 24
    height: dock ? 80 : Math.max(1, Math.ceil(apps.length / cols)) * 96 + 24
    radius: dock ? height / 2 : Config.o.desktop.widgetRadius

    Txt { visible: !c.apps.length; anchors.centerIn: parent; text: "Pick apps in edit mode"; size: 12; color: Theme.inkDim }

    Grid {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        columns: c.dock ? Math.max(1, c.apps.length) : c.cols
        spacing: 0
        Repeater {
            model: c.apps
            Item {
                id: app
                required property var modelData
                width: c.dock ? 60 : 92
                height: c.dock ? 60 : 96
                Rectangle {
                    anchors.fill: parent; anchors.margins: 4
                    radius: c.dock ? width / 2 : 20
                    color: Theme.alpha(Theme.ink, hover.containsMouse ? 0.1 : 0)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: c.dock ? 10 : 14
                    implicitSize: c.dock ? 40 : 44
                    source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
                    scale: hover.containsMouse ? (c.dock ? 1.18 : 1.08) : 1
                    Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                }
                Txt {
                    visible: !c.dock
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
                    width: parent.width - 10
                    horizontalAlignment: Text.AlignHCenter
                    text: app.modelData.name; size: 11
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: app.modelData.execute()
                }
            }
        }
    }
}
