import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs
import qs.parts

// a picture on the desktop, cut to a shape: rounded, a circle, Material's
// cookie, or a polaroid with a caption. `path` is a picture, or a folder whose
// pictures take turns every `minutes`
Item {
    id: c
    property string layout: "rounded"
    property string look
    property var settings: ({})
    property string itemId
    readonly property string path: (settings.path ?? "").replace(/^~/, Theme.home)
    readonly property bool polaroid: layout === "polaroid"
    width: layout === "rounded" ? 300 : polaroid ? 250 : 250
    height: layout === "rounded" ? 220 : polaroid ? 300 : 250

    // a folder's pictures, shuffled once per listing
    property var files: []
    property int shown: 0
    readonly property string file: files.length ? files[shown % files.length] : ""
    onPathChanged: list()
    Component.onCompleted: list()
    function list() {
        files = [];
        if (path === "") return;
        lister.command = ["sh", "-c", "if [ -d \"$1\" ]; then find -L \"$1\" -maxdepth 1 -type f | shuf; else printf '%s\\n' \"$1\"; fi", "sh", path];
        lister.running = true;
    }
    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: c.files = text.split("\n").filter(f => /\.(jpe?g|png|webp|gif|bmp|avif)$/i.test(f))
        }
    }
    Timer {
        interval: Math.max(1, c.settings.minutes ?? 10) * 60000
        repeat: true
        running: c.files.length > 1
        onTriggered: c.shown++
    }

    // the polaroid's paper
    RectangularShadow {
        visible: c.polaroid
        anchors.fill: paper
        radius: Theme.r(6); blur: 24; offset: Qt.vector2d(0, 8)
        color: Qt.rgba(0, 0, 0, 0.45)
        rotation: paper.rotation
    }
    Rectangle {
        id: paper
        visible: c.polaroid
        anchors.fill: parent
        radius: Theme.r(6)
        color: "#f4f1ea"
        rotation: -2.5
        antialiasing: true
        Text {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 14 }
            horizontalAlignment: Text.AlignHCenter
            text: c.settings.caption ?? ""
            color: "#3a3330"
            font.family: "Instrument Serif"; font.italic: true; font.pixelSize: 22
            elide: Text.ElideRight
        }
    }

    // where the picture goes
    Item {
        id: frame
        x: c.polaroid ? 14 : 0
        y: c.polaroid ? 14 : 0
        width: c.polaroid ? c.width - 28 : c.width
        height: c.polaroid ? c.width - 28 : c.height
        rotation: c.polaroid ? -2.5 : 0
        transformOrigin: Item.Center

        // two pictures, so a new one fades in over the last
        Item {
            id: pics
            anchors.fill: parent
            visible: false
            layer.enabled: true
            property bool flip: false
            Image {
                id: a
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(frame.width * 2, frame.height * 2)
                asynchronous: true
                opacity: pics.flip ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 900 } }
            }
            Image {
                id: b
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(frame.width * 2, frame.height * 2)
                asynchronous: true
                opacity: pics.flip ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 900 } }
            }
            Rectangle { anchors.fill: parent; visible: c.file === ""; color: Theme.surfaceHigh }
            Connections {
                target: c
                function onFileChanged() {
                    const url = c.file ? "file://" + c.file : "";
                    if (pics.flip) a.source = url; else b.source = url;
                    pics.flip = !pics.flip;
                }
            }
            Component.onCompleted: a.source = c.file ? "file://" + c.file : ""
        }
        // the shape it's cut to
        Item {
            id: mask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                visible: c.layout !== "cookie"
                radius: c.layout === "circle" ? width / 2 : c.polaroid ? 2 : 28
            }
            Shape {
                anchors.fill: parent
                visible: c.layout === "cookie"
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "white"; strokeWidth: 0; strokeColor: "transparent"
                    PathPolyline {
                        path: {
                            const pts = [], cx = mask.width / 2, cy = mask.height / 2, r = Math.min(cx, cy) * 0.94;
                            for (let i = 0; i <= 240; i++) {
                                const t = i / 240 * Math.PI * 2, rr = r * (1 + 0.06 * Math.cos(9 * t));
                                pts.push(Qt.point(cx + rr * Math.cos(t), cy + rr * Math.sin(t)));
                            }
                            return pts;
                        }
                    }
                }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: pics
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        Column {
            anchors.centerIn: parent
            visible: c.file === ""
            spacing: 6
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "add_photo_alternate"; size: 34; color: Theme.inkDim }
            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "Pick a picture in edit mode"; size: 12; color: Theme.inkDim }
        }
    }
}
