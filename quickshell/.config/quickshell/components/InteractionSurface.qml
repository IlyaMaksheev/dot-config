import QtQuick
import "../theme"

Rectangle {
    id: root
    property bool selected: false
    property bool cursorActive: false
    property bool destructive: false
    property bool navigable: enabled
    property bool pointerEngaged: false
    property bool pointerHovered: pointerEngaged && mouse.containsMouse
    readonly property bool pointerPressed: mouse.pressed
    property bool prominent: false
    property bool showFocusIndicator: true
    property bool showCursorMarker: false
    property bool strictVerticalNavigation: false
    property var navigationLeft: null
    property var navigationRight: null
    property var navigationUp: null
    property var navigationDown: null
    property string accessibleStatus: ""
    property bool controlCenterActivationRegistered: false
    signal activated()
    signal hovered()

    implicitHeight: Appearance.controlCenterRowHeight
    radius: Appearance.controlCenterRadius
    opacity: enabled ? 1 : 0.65
    color: !enabled ? Appearance.surfaceBackground
        : mouse.pressed ? Appearance.surfacePressed
        : cursorActive && selected ? Appearance.surfaceSelectedFocused
        : cursorActive ? Appearance.surfaceFocused
        : pointerHovered ? (prominent ? Appearance.surfaceRaisedHover : Appearance.surfaceHover)
        : selected ? (destructive ? Appearance.dark_red : Appearance.surfaceSelected)
        : prominent ? Appearance.surfaceRaised : Appearance.surfaceBackground

    Behavior on color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPositionChanged: {
            if (!root.pointerEngaged) {
                root.pointerEngaged = true;
                root.hovered();
            }
        }
        onContainsMouseChanged: if (!containsMouse) root.pointerEngaged = false
        onClicked: {
            if (!root.pointerEngaged) {
                root.pointerEngaged = true;
                root.hovered();
            }
            if (root.enabled) root.activated();
        }
    }

    Rectangle {
        visible: root.showCursorMarker && root.cursorActive
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        width: Math.max(8, parent.width / 4)
        height: 2
        radius: 1
        color: Appearance.textPrimary
    }

    FocusIndicator { active: root.showFocusIndicator && root.cursorActive }
}
