import QtQuick
import "../controlcenter"
import "../../components"
import "../../theme"

MouseArea {
    id: root

    required property string outputName
    implicitWidth: label.implicitWidth + Appearance.trayItemHorizontalPadding * 2
    implicitHeight: Appearance.barHeight - Appearance.accentHeight
    hoverEnabled: true
    onClicked: ControlCenter.toggle(outputName)

    StyledText {
        id: label
        anchors.centerIn: parent
        text: "󰒓"
        color: root.containsMouse || (ControlCenter.isOpen && ControlCenter.targetOutput === root.outputName)
            ? Appearance.light_green
            : Appearance.light1
    }
}
