import Quickshell
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// the night ahead (Night.qml): the moon as it is, and
//   moon: the moon, big, its phase and how much of it is lit
//   card: the moon small, sunset to sunrise, whether the clouds let the stars through,
//   and a meteor shower near its peak
Card {
    id: c
    property string layout: "moon"
    property var settings: ({})
    property string itemId
    width: layout === "card" ? 340 : 220
    height: layout === "card" ? 150 : 230

    function hm(iso) { return iso ? Qt.formatTime(new Date(iso), Config.o.island.clock24 ? "HH:mm" : "h:mm AP") : "—"; }

    // moon
    Item {
        visible: c.layout === "moon"
        anchors.fill: parent
        Moon {
            id: big
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 22 }
            size: 112
            light: Qt.tint(Theme.ink, Theme.alpha(Theme.primary, 0.12))
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.alpha(Theme.primary, 0.55); shadowBlur: 1; blurMax: 40; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
        }
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: big.bottom; topMargin: 14 }
            spacing: 2
            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Night.phaseName; size: 15; weight: Font.DemiBold }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(Night.lit * 100) + "% lit" + (Night.shower ? "  ·  " + Night.shower.name : "")
                size: 12; color: Theme.inkDim
            }
        }
    }

    // card
    Item {
        visible: c.layout === "card"
        anchors.fill: parent
        Moon {
            id: small
            x: 20; anchors.verticalCenter: parent.verticalCenter
            size: 74
            light: Qt.tint(Theme.ink, Theme.alpha(Theme.primary, 0.12))
        }
        Column {
            anchors { left: small.right; leftMargin: 18; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            spacing: 4
            Txt { width: parent.width; text: "Tonight  ·  " + Night.phaseName; size: 14; weight: Font.DemiBold }
            Row {
                spacing: 6
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "wb_twilight"; size: 16; color: Theme.tertiary }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: c.hm(Weather.sunset) + "  →  " + c.hm(Weather.sunriseNext || Weather.sunrise)
                    size: 12; color: Theme.inkDim; font.features: { "tnum": 1 }
                }
            }
            Row {
                visible: Night.stars !== ""
                spacing: 6
                Icon { anchors.verticalCenter: parent.verticalCenter; name: Night.clouds < 25 ? "auto_awesome" : "cloud"; size: 16; color: Theme.primary }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Night.stars; size: 12; color: Theme.inkDim }
            }
            Row {
                visible: Night.shower !== null
                spacing: 6
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "flare"; size: 16; color: Theme.primary }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Night.showerWords; size: 12; color: Theme.inkDim }
            }
        }
    }
}
