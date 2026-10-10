pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick

// the compositor: workspaces, windows, the focused output. One backend per
// compositor (wm/) fills the same shapes, so the rest of the shell never asks
// which one it's on:
//   workspaces  [{ index, output, visible, windows }]   index counts from 1 per output
//   windows     [{ id, title, app_id, output, workspace, visible, focused, floating, fullscreen, state }]
//               (state "scratchpad" for windows parked out of sight)
Singleton {
    id: wm

    // aro, hyprland, niri, or "" (anything else with layer-shell: no workspaces)
    readonly property string name: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "hyprland"
        : Quickshell.env("NIRI_SOCKET") ? "niri"
        : Quickshell.env("ARO_SOCKET") || (Quickshell.env("XDG_CURRENT_DESKTOP") ?? "").toLowerCase() === "aro" ? "aro" : ""

    property var workspaces: []
    property var windows: []
    property string focusedTitle: ""
    property string focusedApp: ""
    property string focusedOutput: Quickshell.screens[0]?.name ?? ""
    // foreign-toplevel handles, for activate() and close(): the list only fills
    // in after first use, so it is bound here, at startup
    readonly property var toplevels: ToplevelManager.toplevels.values
    property var mru: []                // window ids, the most recently focused first
    function touch(id) {
        if (!id) return;
        mru = [id].concat(mru.filter(x => x !== id)).slice(0, 200);
    }

    function wsFor(output) { return workspaces.filter(w => w.output === output); }
    function current(output) {
        const w = workspaces.find(w => w.output === output && w.visible);
        return w ? w.index : 1;
    }
    // windows on the workspace shown on this output, scratchpad aside
    function busy(output) {
        return windows.some(w => w.output === output && w.visible && w.state !== "scratchpad" && !w.floating);
    }
    function fullscreen(output) { return windows.some(w => w.output === output && w.visible && w.fullscreen); }

    function focusWorkspace(index) { backend.item?.focusWorkspace(index); }
    function quit() { backend.item?.quit(); }

    LazyLoader {
        id: backend
        active: wm.name !== ""
        source: Qt.resolvedUrl(({ aro: "wm/AroBackend.qml", hyprland: "wm/HyprBackend.qml", niri: "wm/NiriBackend.qml" })[wm.name] ?? "")
    }
}
