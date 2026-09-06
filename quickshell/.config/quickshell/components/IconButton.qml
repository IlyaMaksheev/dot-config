import QtQuick
import "../theme"

InteractionSurface {
    id: root
    property string icon: ""
    property real iconPixelSize: Appearance.fontPixelSize
    property bool glyphBold: false
    implicitWidth: Appearance.controlCenterRowHeight
    implicitHeight: Appearance.controlCenterRowHeight

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: !root.enabled ? Appearance.disabledColor
            : root.destructive && !root.cursorActive && !root.selected ? Appearance.destructiveColor
            : Appearance.textPrimary
        font.family: Appearance.fontFamily
        font.pixelSize: root.iconPixelSize
        font.bold: root.glyphBold || root.cursorActive
    }
}
