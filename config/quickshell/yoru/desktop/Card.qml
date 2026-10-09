import QtQuick
import qs

// the glass a desktop widget sits on
Rectangle {
    width: 320
    radius: 28
    color: Theme.alpha(Theme.surfaceLowest, 0.62)
    border.width: 1
    border.color: Theme.alpha(Theme.outlineVariant, 0.5)
}
