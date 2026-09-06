import QtQuick
import "../theme"

Rectangle {
    property bool focused: false

    color: Appearance.panelBackground
    border.width: Appearance.controlCenterBorderWidth
    border.color: focused ? Appearance.focusColor : Appearance.panelBorder
    Behavior on border.color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }
    radius: Appearance.controlCenterRadius
}
