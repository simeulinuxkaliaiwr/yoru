pragma Singleton

import Quickshell
import QtQuick

// the night sky, worked out here (no service to ask): the moon's phase, a meteor shower
// near its peak, and whether tonight's clouds let the stars through (the weather's hourly
// cloud cover). The Tonight widget shows it; the sky's shooting stars follow the showers
Singleton {
    id: n

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // days since a known new moon (6 January 2000, 18:14 UTC), in synodic months
    readonly property real phase: {
        const days = (clock.date.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
        const p = (days / 29.530588853) % 1;
        return p < 0 ? p + 1 : p;
    }
    readonly property real lit: (1 - Math.cos(2 * Math.PI * phase)) / 2
    readonly property bool waxing: phase < 0.5
    readonly property string phaseName: phase < 0.03 || phase > 0.97 ? "New moon"
        : phase < 0.22 ? "Waxing crescent" : phase < 0.28 ? "First quarter" : phase < 0.47 ? "Waxing gibbous"
        : phase < 0.53 ? "Full moon" : phase < 0.72 ? "Waning gibbous" : phase < 0.78 ? "Last quarter" : "Waning crescent"
    // seen from the south, the moon is the other way round
    readonly property bool south: Weather.located && Weather.lat < 0

    // the year's showers at their peaks (month, day) and how many an hour they bring at best
    readonly property var showers: [
        { name: "Quadrantids", m: 1, d: 3, rate: 110 }, { name: "Lyrids", m: 4, d: 22, rate: 18 },
        { name: "Eta Aquariids", m: 5, d: 6, rate: 50 }, { name: "Delta Aquariids", m: 7, d: 30, rate: 25 },
        { name: "Perseids", m: 8, d: 12, rate: 100 }, { name: "Draconids", m: 10, d: 8, rate: 10 },
        { name: "Orionids", m: 10, d: 21, rate: 20 }, { name: "Taurids", m: 11, d: 5, rate: 5 },
        { name: "Leonids", m: 11, d: 17, rate: 15 }, { name: "Geminids", m: 12, d: 14, rate: 150 },
        { name: "Ursids", m: 12, d: 22, rate: 10 }
    ]
    // one within a few days of its peak: { name, rate, days } (days from the peak, + after)
    readonly property var shower: {
        const t = clock.date, today = new Date(t.getFullYear(), t.getMonth(), t.getDate());
        let best = null;
        for (const s of showers) {
            for (const y of [t.getFullYear() - 1, t.getFullYear(), t.getFullYear() + 1]) {
                const off = Math.round((today - new Date(y, s.m - 1, s.d)) / 86400000);
                if (Math.abs(off) <= 3 && (!best || Math.abs(off) < Math.abs(best.days))) best = { name: s.name, rate: s.rate, days: off };
            }
        }
        return best;
    }
    readonly property string showerWords: !shower ? "" : shower.days === 0 ? "The " + shower.name + " peak tonight"
        : shower.days < 0 ? "The " + shower.name + " peak in " + (-shower.days) + (shower.days === -1 ? " day" : " days")
        : "The " + shower.name + ", just past their peak"

    // tonight's clouds: the hours from nine to three, on average (-1 while the weather doesn't say)
    readonly property real clouds: {
        const night = Weather.hours.filter(h => { const hr = new Date(h.time).getHours(); return (hr >= 21 || hr < 3) && h.cloud >= 0; });
        return night.length ? night.reduce((a, h) => a + h.cloud, 0) / night.length : -1;
    }
    readonly property string stars: clouds < 0 ? "" : clouds < 25 ? "Clear tonight: a good night for stars"
        : clouds < 60 ? "Some clouds tonight" : "Cloudy tonight"
}
