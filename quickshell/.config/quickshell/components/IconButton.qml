import QtQuick
import "../theme"

InteractionSurface {
    id: root
    property string icon: ""
    implicitWidth: Appearance.controlCenterRowHeight
    implicitHeight: Appearance.controlCenterRowHeight

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.enabled ? Appearance.textPrimary : Appearance.disabledColor
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontPixelSize
    }
}
