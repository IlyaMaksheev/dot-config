import Quickshell
import QtQuick
import "../../theme"

Scope {

    Variants {
        model: Quickshell.screens

        // qmllint disable uncreatable-type
        PanelWindow {
            required property var modelData

            color: Appearance.dark0_soft
            anchors {
                top: true
                left: true
                right: true
            }
            screen: modelData
            implicitHeight: Appearance.barHeight

            Workspaces {
                outputName: modelData.name
            }

            ActiveWindow {
                outputName: modelData.name
                width: Math.min(implicitWidth, parent.width / 2)

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: 4
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Tray {}
                ClockWidget {}
                ControlCenterTrigger {
                    outputName: modelData.name
                }
            }

            Rectangle {
                height: Appearance.accentHeight
                color: Appearance.dark_green_hard

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
            }
        }
        // qmllint enable uncreatable-type
    }
}
