import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Rectangle {

    width: timeText.implicitWidth + Appearance.workspaceHorizontalPadding
    height: Appearance.barHeight

    color: timeMouse.containsMouse ? Appearance.dark2 : "transparent"

    StyledText {
        id: timeText

        text: Time.time
        anchors.centerIn: parent
    }

    MouseArea {
        id: timeMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
