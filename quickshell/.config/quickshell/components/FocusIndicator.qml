import QtQuick
import "../theme"

Rectangle {
    required property bool active
    anchors.fill: parent
    anchors.margins: -Appearance.controlCenterFocusWidth
    color: "transparent"
    z: 100
    border.width: active ? Appearance.controlCenterFocusWidth : 0
    border.color: Appearance.focusColor
    radius: Appearance.controlCenterRadius
    visible: active
}
