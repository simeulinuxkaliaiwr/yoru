import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.weather

    Section {
        icon: "partly_cloudy_day"; title: "Weather"
        SetRow {
            icon: "location_on"; label: "City"; hint: "Leave it empty to go by your IP address"
            Field { text: c.city; placeholder: "São Paulo"; onEdited: t => c.city = t }
        }
        SetRow { icon: "thermostat"; label: "Fahrenheit"; Toggle { checked: c.fahrenheit; onToggled: on => c.fahrenheit = on } }
    }
}
