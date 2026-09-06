import QtQuick
import "../controlcenter"
import "../../components"
import "../../theme"

MouseArea {
    id: root

    required property string outputName
    implicitWidth: Math.max(Appearance.barHeight, label.implicitWidth + Appearance.trayItemHorizontalPadding * 2)
    implicitHeight: Appearance.barHeight - Appearance.accentHeight
    hoverEnabled: true
    onClicked: ControlCenter.toggle(outputName)

    Rectangle {
        anchors.fill: parent
        color: ControlCenter.isOpen && ControlCenter.targetOutput === root.outputName
            ? Appearance.dark_green_hard
            : root.containsMouse ? Appearance.dark2 : "transparent"
        radius: Appearance.controlCenterRadius
        Behavior on color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: "󰒓"
        font.pixelSize: Appearance.fontPixelSize + 3
        color: root.containsMouse || (ControlCenter.isOpen && ControlCenter.targetOutput === root.outputName)
            ? Appearance.light_green
            : Appearance.light1
    }
}
