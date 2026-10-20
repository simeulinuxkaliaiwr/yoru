import Quickshell
import Quickshell.Io
import QtQuick

// hands the start page settings to Firefox's new tab page. A file:// page
// can't fetch JSON beside it, but it can load a script, so they go out as
// ~/startpages/yoru-start.js whenever they change
Scope {
    id: start
    readonly property var s: Config.o.start
    readonly property string text: "// written by yoru's shell from ~/.config/yoru/config.json (Start page)\nwindow.YORU_START = "
        + JSON.stringify({
            layout: s.layout, greeting: s.greeting, name: s.name, clock: s.clock, seconds: s.seconds,
            date: s.date, engine: s.engine, imageEngine: s.imageEngine, links: s.links, blur: s.blur, dim: s.dim, keys: s.keys, focus: s.focus
        }, null, 2) + ";\n"

    onTextChanged: save.restart()
    Component.onCompleted: save.restart()
    Timer { id: save; interval: 400; onTriggered: file.setText(start.text) }

    FileView {
        id: file
        path: Theme.home + "/startpages/yoru-start.js"
        printErrors: false
        blockLoading: false
    }
}
