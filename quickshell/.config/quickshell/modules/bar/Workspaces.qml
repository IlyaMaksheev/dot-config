import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Row {
    id: workspaceWidget

    required property string outputName

    z: 1
    spacing: 6

    readonly property var workspaces: Niri.workspaces.filter(workspace => workspace.output === outputName).sort((a, b) => a.idx - b.idx).map(workspace => ({
                id: workspace.id,
                idx: workspace.idx,
                isActive: workspace.is_active,
                isUrgent: workspace.is_urgent
            }))

    Repeater {
        model: workspaceWidget.workspaces

        Rectangle {
            id: workspaceDelegate

            required property var modelData

            width: workspaceLabel.implicitWidth + Appearance.workspaceHorizontalPadding * 2
            height: Appearance.barHeight
            color: workspaceDelegate.modelData.isUrgent
                ? Appearance.faded_yellow
                : workspaceDelegate.modelData.isActive
                    ? Appearance.dark_green_hard
                    : workspaceMouse.containsMouse
                        ? Appearance.dark2
                        : "transparent"

            StyledText {
                id: workspaceLabel

                anchors.centerIn: parent
                text: workspaceDelegate.modelData.idx
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: Appearance.accentHeight
                visible: workspaceDelegate.modelData.isUrgent
                    || workspaceDelegate.modelData.isActive
                    || workspaceMouse.containsMouse
                color: workspaceDelegate.modelData.isUrgent
                    ? Appearance.bright_yellow
                    : workspaceDelegate.modelData.isActive
                        ? Appearance.bright_green
                        : Appearance.faded_green
            }

            MouseArea {
                id: workspaceMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(workspaceDelegate.modelData.id)
            }
        }
    }
}
