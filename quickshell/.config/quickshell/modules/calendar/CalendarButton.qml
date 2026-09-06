import QtQuick
import "../../theme"

Rectangle {
    id: root
    required property string text
    signal clicked()
    implicitWidth: label.implicitWidth + Appearance.calendarPadding * 2
    implicitHeight: Appearance.calendarCellHeight
    color: mouse.containsMouse ? Appearance.surfaceHover : "transparent"
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Appearance.light_green
        font.family: Appearance.calendarFontFamily
        font.pixelSize: Appearance.calendarFontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
