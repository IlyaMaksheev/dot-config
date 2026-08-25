import QtQuick
import "../theme"

InteractionSurface {
    id: root
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property string label: ""
    signal valueRequested(real requestedValue)

    function clamp(candidate) { return Math.max(from, Math.min(to, candidate)); }
    function adjust(direction) { valueRequested(clamp(value + direction * stepSize)); }

    implicitHeight: Appearance.controlCenterSliderHeight

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 3
        width: parent.width * ((root.value - root.from) / Math.max(0.0001, root.to - root.from))
        color: Appearance.bright_green
    }
    Text { anchors.centerIn: parent; text: root.label; color: root.enabled ? Appearance.textPrimary : Appearance.disabledColor; font.family: Appearance.fontFamily; font.pixelSize: Appearance.fontPixelSize }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered()
        onPressed: mouse => { if (root.enabled) root.valueRequested(root.clamp(root.from + mouse.x / width * (root.to - root.from))); }
        onPositionChanged: mouse => { if (root.enabled && pressed) root.valueRequested(root.clamp(root.from + mouse.x / width * (root.to - root.from))); }
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
