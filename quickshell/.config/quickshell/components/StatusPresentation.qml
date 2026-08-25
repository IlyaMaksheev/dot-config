import QtQuick
import "../theme"

Row {
    property string label: ""
    property bool unavailable: false
    spacing: 6

    Text {
        text: parent.unavailable ? "!" : "•"
        color: parent.unavailable ? Appearance.destructiveColor : Appearance.bright_green
        font.family: Appearance.fontFamily
    }
    Text {
        text: parent.label
        color: parent.unavailable ? Appearance.disabledColor : Appearance.textSecondary
        font.family: Appearance.fontFamily
        font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
        elide: Text.ElideRight
    }
}
