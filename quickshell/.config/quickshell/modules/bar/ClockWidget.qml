import QtQuick
import "../../components"
import "../../services"
import "../../theme"

MouseArea {
    id: root

    implicitWidth: label.implicitWidth + Appearance.clockHorizontalPadding * 2
    implicitHeight: Appearance.barHeight
    hoverEnabled: true

    Rectangle {
        anchors.fill: parent
        color: root.containsMouse ? Appearance.clockHoverBackground : "transparent"

        Behavior on color {
            ColorAnimation { duration: Appearance.feedbackAnimationDuration }
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: Time.time
    }

    Rectangle {
        visible: root.containsMouse
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: Appearance.accentHeight
        color: Appearance.clockHoverAccent
    }
}
