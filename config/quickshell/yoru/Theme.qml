pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// yoru's palette, type and motion. The colours are Material 3 roles that the
// `yoru` script derives from the wallpaper (~/.cache/yoru/palette.json); a
// new wallpaper fades every colour on screen across to the new ones.
Singleton {
    id: theme

    property color surface: "#0f1218"
    property color surfaceLowest: "#0a0d12"
    property color surfaceLow: "#171b22"
    property color surfaceMid: "#1b2028"
    property color surfaceHigh: "#262a33"
    property color surfaceHighest: "#30353e"
    property color ink: "#e0e2ec"
    property color inkDim: "#c3c6d1"
    property color outline: "#8d909b"
    property color outlineVariant: "#434751"
    property color primary: "#a9c7ff"
    property color inkPrimary: "#0b305f"
    property color primaryContainer: "#284777"
    property color inkPrimaryContainer: "#d6e3ff"
    property color secondary: "#bdc7dc"
    property color secondaryContainer: "#3e4759"
    property color inkSecondaryContainer: "#d9e3f8"
    property color tertiary: "#dcbce1"
    property color tertiaryContainer: "#573e5c"
    property color inkTertiaryContainer: "#f9d8fe"
    property color danger: "#ffb4ab"

    property string wallpaper: ""
    property string still: ""           // the wallpaper as an image (a video's frame)
    property bool video: false

    // the island is darker than any surface: it reads as a hole in the screen
    readonly property color island: Qt.darker(surfaceLowest, 1.6)

    Behavior on surface { ColorAnimation { duration: theme.recolourMs } }
    Behavior on surfaceLowest { ColorAnimation { duration: theme.recolourMs } }
    Behavior on surfaceLow { ColorAnimation { duration: theme.recolourMs } }
    Behavior on surfaceMid { ColorAnimation { duration: theme.recolourMs } }
    Behavior on surfaceHigh { ColorAnimation { duration: theme.recolourMs } }
    Behavior on surfaceHighest { ColorAnimation { duration: theme.recolourMs } }
    Behavior on ink { ColorAnimation { duration: theme.recolourMs } }
    Behavior on inkDim { ColorAnimation { duration: theme.recolourMs } }
    Behavior on outline { ColorAnimation { duration: theme.recolourMs } }
    Behavior on outlineVariant { ColorAnimation { duration: theme.recolourMs } }
    Behavior on primary { ColorAnimation { duration: theme.recolourMs } }
    Behavior on inkPrimary { ColorAnimation { duration: theme.recolourMs } }
    Behavior on primaryContainer { ColorAnimation { duration: theme.recolourMs } }
    Behavior on inkPrimaryContainer { ColorAnimation { duration: theme.recolourMs } }
    Behavior on secondary { ColorAnimation { duration: theme.recolourMs } }
    Behavior on secondaryContainer { ColorAnimation { duration: theme.recolourMs } }
    Behavior on inkSecondaryContainer { ColorAnimation { duration: theme.recolourMs } }
    Behavior on tertiary { ColorAnimation { duration: theme.recolourMs } }
    Behavior on tertiaryContainer { ColorAnimation { duration: theme.recolourMs } }
    Behavior on inkTertiaryContainer { ColorAnimation { duration: theme.recolourMs } }
    Behavior on danger { ColorAnimation { duration: theme.recolourMs } }

    // ── type ────────────────────────────────────────────────────────
    readonly property string sans: "Geist"
    readonly property string mono: "Geist Mono"
    readonly property string icons: "Material Symbols Rounded"

    // ── shape ───────────────────────────────────────────────────────
    readonly property int rXs: 8
    readonly property int rSm: 12
    readonly property int rMd: 18
    readonly property int rLg: 26
    readonly property int gap: 10

    // ── motion: Material 3 Expressive curves ────────────────────────
    // spatial curves overshoot a little; effect curves (colour, opacity) never do
    readonly property var spatial: [0.38, 1.21, 0.22, 1.0, 1, 1]
    readonly property var spatialSlow: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property var emphasized: [0.05, 0.7, 0.1, 1.0, 1, 1]
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1, 1]
    readonly property var effects: [0.34, 0.8, 0.34, 1.0, 1, 1]
    readonly property int fast: 220
    readonly property int normal: 380
    readonly property int slow: 560
    readonly property int recolourMs: 1100

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: home + "/.cache/yoru"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    FileView {
        path: theme.cacheDir + "/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let p;
            try { p = JSON.parse(text()); } catch (e) { return; }
            const c = k => "#" + p[k];
            theme.surface = c("surface");
            theme.surfaceLowest = c("surface_container_lowest");
            theme.surfaceLow = c("surface_container_low");
            theme.surfaceMid = c("surface_container");
            theme.surfaceHigh = c("surface_container_high");
            theme.surfaceHighest = c("surface_container_highest");
            theme.ink = c("on_surface");
            theme.inkDim = c("on_surface_variant");
            theme.outline = c("outline");
            theme.outlineVariant = c("outline_variant");
            theme.primary = c("primary");
            theme.inkPrimary = c("on_primary");
            theme.primaryContainer = c("primary_container");
            theme.inkPrimaryContainer = c("on_primary_container");
            theme.secondary = c("secondary");
            theme.secondaryContainer = c("secondary_container");
            theme.inkSecondaryContainer = c("on_secondary_container");
            theme.tertiary = c("tertiary");
            theme.tertiaryContainer = c("tertiary_container");
            theme.inkTertiaryContainer = c("on_tertiary_container");
            theme.danger = c("error");
            theme.wallpaper = p.wallpaper ?? "";
            theme.still = p.still ?? "";
            theme.video = !!p.video;
        }
    }
}
