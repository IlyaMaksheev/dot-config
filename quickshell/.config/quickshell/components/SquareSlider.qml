import QtQuick
import "../theme"

InteractionSurface {
    id: root
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property string label: ""
    property bool adjustmentMode: false
    readonly property bool pointerAdjusting: enabled && sliderMouse.pressed
    readonly property bool neutralEmphasis: enabled && (cursorActive
        || (pointerEngaged && sliderMouse.containsMouse))
    readonly property bool accentActive: enabled && (adjustmentMode || pointerAdjusting)
    signal valueRequested(real requestedValue)

    function clamp(candidate) { return Math.max(from, Math.min(to, candidate)); }
    function adjust(direction) { valueRequested(clamp(value + direction * stepSize)); }

    implicitHeight: Appearance.controlCenterSliderHeight

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.controlCenterFocusClearance
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.controlCenterFocusClearance
        height: 3
        width: (parent.width - Appearance.controlCenterFocusClearance * 2)
            * ((root.value - root.from) / Math.max(0.0001, root.to - root.from))
        color: root.accentActive ? Appearance.bright_green
            : root.neutralEmphasis ? Appearance.textSecondary : Appearance.dark4
        Behavior on color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }
    }
    Text {
        anchors.centerIn: parent
        text: root.label
        color: !root.enabled ? Appearance.disabledColor
            : root.accentActive ? Appearance.bright_green
            : root.neutralEmphasis ? Appearance.textPrimary : Appearance.textSecondary
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontPixelSize
        Behavior on color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: if (!containsMouse) root.pointerEngaged = false
        onPressed: mouse => {
            if (!root.pointerEngaged) {
                root.pointerEngaged = true;
                root.hovered();
            }
            if (root.enabled)
                root.valueRequested(root.clamp(root.from + mouse.x / width * (root.to - root.from)));
        }
        onPositionChanged: mouse => {
            if (!root.pointerEngaged) {
                root.pointerEngaged = true;
                root.hovered();
            }
            if (root.enabled && pressed)
                root.valueRequested(root.clamp(root.from + mouse.x / width * (root.to - root.from)));
        }
        onWheel: wheel => {
            if (root.enabled) {
                root.adjust(wheel.angleDelta.y >= 0 ? 1 : -1);
                wheel.accepted = true;
            } else {
                wheel.accepted = false;
            }
        }
    }
}
