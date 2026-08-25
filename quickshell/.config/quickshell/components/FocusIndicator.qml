import QtQuick
import "../theme"

Rectangle {
    required property bool active
    anchors.fill: parent
    color: "transparent"
    border.width: active ? Appearance.controlCenterFocusWidth : 0
    border.color: Appearance.focusColor
    radius: Appearance.controlCenterRadius
    visible: active
}
