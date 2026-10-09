pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// the player worth showing: the one playing, else the last one that did
Singleton {
    id: media

    property var last: null
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle !== "" || p.isPlaying)
    readonly property var player: players.find(p => p.isPlaying) ?? (players.includes(last) ? last : players[0] ?? null)
    readonly property bool playing: !!player && player.isPlaying
    readonly property string title: player?.trackTitle || ""
    readonly property string artist: player?.trackArtist || player?.identity || ""
    readonly property string art: player?.trackArtUrl || ""
    readonly property real length: player?.lengthSupported ? player.length : 0
    property real position: 0

    onPlayerChanged: if (player && player.isPlaying) last = player
    Connections {
        target: media.player
        function onIsPlayingChanged() { if (media.player.isPlaying) media.last = media.player; }
    }

    // mpris doesn't push the position; poll it while it moves
    Timer {
        interval: 500; repeat: true; triggeredOnStart: true
        running: media.playing
        onTriggered: { media.player.positionChanged(); media.position = media.player.position; }
    }
    onTitleChanged: position = player?.position ?? 0

    function toggle() { player?.togglePlaying(); }
    function next() { player?.next(); }
    function prev() { player?.previous(); }
    function seek(frac) { if (player && length > 0) { player.position = frac * length; position = player.position; } }

    function time(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
