pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// the weather from Open-Meteo (no key needed): the settings' city, or your IP's
Singleton {
    id: w

    property bool ready: false
    property string place: ""
    property real temp: 0
    property real feels: 0
    property int code: 0
    property bool day: true
    property int humidity: 0
    property real wind: 0
    property var days: []               // [{ date, max, min, code }]
    readonly property string unit: Config.o.weather.fahrenheit ? "°F" : "°C"

    readonly property string city: Config.o.weather.city
    readonly property bool fahrenheit: Config.o.weather.fahrenheit
    onCityChanged: soon.restart()
    onFahrenheitChanged: soon.restart()
    Timer { id: soon; interval: 800; onTriggered: w.refresh() }
    Timer { interval: 20 * 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: w.refresh() }

    function refresh() {
        const enc = encodeURIComponent(city.trim());
        const units = fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";
        // find the place, then ask for its weather; one shell line keeps it to one process
        const where = city.trim() !== ""
            ? `curl -sf -m 8 "https://geocoding-api.open-meteo.com/v1/search?name=${enc}&count=1" | jq -r '.results[0] | "\\(.latitude) \\(.longitude) \\(.name)"'`
            : `curl -sf -m 8 https://ipinfo.io/json | jq -r '"\\(.loc | split(",") | .[0]) \\(.loc | split(",") | .[1]) \\(.city)"'`;
        query.command = ["sh", "-c", `set -- $(${where}); [ -n "$1" ] || exit 1; lat=$1 lon=$2; shift 2; echo "$*";
curl -sf -m 8 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=4${units}"`];
        query.running = true;
    }

    Process {
        id: query
        stdout: StdioCollector {
            onStreamFinished: {
                const nl = this.text.indexOf("\n");
                if (nl < 0) return;
                let d;
                try { d = JSON.parse(this.text.slice(nl + 1)); } catch (e) { return; }
                w.place = this.text.slice(0, nl);
                const c = d.current;
                w.temp = c.temperature_2m;
                w.feels = c.apparent_temperature;
                w.code = c.weather_code;
                w.day = c.is_day === 1;
                w.humidity = c.relative_humidity_2m;
                w.wind = c.wind_speed_10m;
                w.days = d.daily.time.map((t, i) => ({
                    date: t, max: d.daily.temperature_2m_max[i], min: d.daily.temperature_2m_min[i], code: d.daily.weather_code[i]
                }));
                w.ready = true;
            }
        }
    }

    // WMO weather codes, as Material Symbols and words
    function icon(code, isDay) {
        if (code === 0) return isDay ? "clear_day" : "clear_night";
        if (code <= 2) return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (code === 3) return "cloud";
        if (code <= 48) return "foggy";
        if (code <= 57) return "rainy_light";
        if (code <= 67) return "rainy";
        if (code <= 77) return "weather_snowy";
        if (code <= 82) return "rainy_heavy";
        if (code <= 86) return "snowing_heavy";
        return "thunderstorm";
    }
    function words(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code <= 48) return "Fog";
        if (code <= 57) return "Drizzle";
        if (code <= 67) return "Rain";
        if (code <= 77) return "Snow";
        if (code <= 82) return "Showers";
        if (code <= 86) return "Snow showers";
        return "Thunderstorm";
    }
}
