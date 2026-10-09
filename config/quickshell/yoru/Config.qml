pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// yoru's settings: ~/.config/yoru/config.json. The settings window (mod+i)
// edits it and the shell follows the file, so changes show at once; the file
// is also fine to edit by hand.
Singleton {
    id: config
    readonly property alias o: adapter
    readonly property string path: Quickshell.env("HOME") + "/.config/yoru/config.json"

    FileView {
        path: config.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // the first run: write the defaults out so there's a file to edit
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string scheme: "scheme-tonal-spot"   // matugen's scheme types
                property real speed: 1.0                      // animation speed, > 1 is faster
            }

            property JsonObject wallpaper: JsonObject {
                // ripple, fade, wipe, disc, stripes, zoom, honeycomb, pixelate, or random
                property string transition: "random"
                property list<string> pool: ["ripple", "fade", "wipe", "disc", "stripes", "zoom", "honeycomb", "pixelate"]
                property int duration: 1500
                property real smoothness: 0.3                 // the soft edge, 0..1
                property bool parallax: true
                property bool pauseCovered: true              // videos pause under windows
                property int rotateMinutes: 0                 // 0: never change on its own
                property bool shuffle: true
                property list<string> dirs: ["~/Pictures/nightcore", "~/Pictures/Wallpapers"]
            }

            property JsonObject desktop: JsonObject {
                property bool clock: true
                // thin, bold, stacked, outline, mono, split, words, kanji, serif, analog
                property string clockStyle: "thin"
                property string clockPosition: "bottom-left"  // bottom-left, center, top-left
                property bool visualizer: true
                property string visualizerStyle: "bars"       // bars, mirror, wave, dots
                property bool visualizerBusy: true            // on workspaces with windows too
                property real visualizerOpacity: 0.85
                property bool widgets: true
                property string widgetSide: "right"
                property string widgetStyle: "glass"          // glass, solid, tonal, outline, neon, minimal
                property int widgetRadius: 28
                property bool weather: true
                property bool system: true
                property bool media: true
                property bool calendar: false
                property bool day: false
            }

            property JsonObject island: JsonObject {
                property bool clock24: true
                property bool showMedia: true
                property bool batteryPercent: true
                property string workspaces: "pills"           // pills, numbers
                property int toastSeconds: 5
            }

            property JsonObject lock: JsonObject {
                property bool enabled: true
                property real blur: 0.8
                property real dim: 0.35
                property bool media: true
                property bool power: true
                property string clockStyle: "thin"
                property int lockAfterMinutes: 10
            }

            property JsonObject weather: JsonObject {
                property string city: "São Paulo"             // empty: from your IP
                property bool fahrenheit: false
            }
        }
    }
}
