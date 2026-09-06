import QtQuick
import "../../components"
import "../../services"
import "../../theme"
import "../calendar"

MouseArea {
    id: root
    required property string outputName
    readonly property bool calendarOpen: Calendar.isOpen && Calendar.targetOutput === outputName
    acceptedButtons: Qt.LeftButton
    onClicked: Calendar.toggle(outputName)

    implicitWidth: label.implicitWidth + Appearance.clockHorizontalPadding * 2
    implicitHeight: Appearance.barHeight
    hoverEnabled: true

    Rectangle {
        anchors.fill: parent
        color: root.calendarOpen ? Appearance.dark_green_hard
            : root.containsMouse ? Appearance.clockHoverBackground : "transparent"

        Behavior on color {
            ColorAnimation { duration: Appearance.feedbackAnimationDuration }
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: Time.time
        color: root.calendarOpen ? Appearance.light_green : Appearance.light1
    }

    Rectangle {
        visible: root.containsMouse || root.calendarOpen
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: Appearance.accentHeight
        color: root.calendarOpen ? Appearance.focusColor : Appearance.clockHoverAccent
    }
}
