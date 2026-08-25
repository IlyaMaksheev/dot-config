import QtQuick
import "../theme"

Rectangle {
    id: root
    property bool selected: false
    property bool cursorActive: false
    property bool destructive: false
    property bool navigable: enabled
    property string accessibleStatus: ""
    property bool controlCenterActivationRegistered: false
    signal activated()
    signal hovered()

    implicitHeight: Appearance.controlCenterRowHeight
    radius: Appearance.controlCenterRadius
    opacity: enabled ? 1 : 0.65
    color: !enabled ? Appearance.surfaceBackground
        : destructive ? Appearance.dark_red
        : mouse.pressed ? Appearance.surfacePressed
        : mouse.containsMouse ? Appearance.surfaceHover
        : selected ? Appearance.surfaceSelected
        : Appearance.surfaceBackground

    Behavior on color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.hovered()
        onClicked: { if (root.enabled) root.activated(); }
    }

    FocusIndicator { active: root.cursorActive }
}
