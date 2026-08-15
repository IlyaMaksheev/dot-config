import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Row {
    id: row

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem
            required property var modelData
            readonly property bool needsAttention: modelData.status === Status.NeedsAttention
            readonly property bool passive: modelData.status === Status.Passive
            readonly property string tooltipText: {
                const title = modelData.tooltipTitle || modelData.title;
                const description = modelData.tooltipDescription;

                if (title && description)
                    return title + "\n" + description;

                return title || description || "";
            }

            width: Appearance.trayIconSize + Appearance.trayItemHorizontalPadding * 2
            height: Appearance.barHeight

            Rectangle {
                anchors.fill: parent
                color: trayItem.needsAttention ? Appearance.faded_yellow : (mouseArea.containsMouse ? Appearance.dark2 : "transparent")
            }

            Rectangle {
                visible: trayItem.needsAttention || mouseArea.containsMouse
                height: Appearance.accentHeight
                color: trayItem.needsAttention ? Appearance.bright_yellow : Appearance.bright_green
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitWidth: Appearance.trayIconSize
                implicitHeight: Appearance.trayIconSize
                source: trayItem.modelData.icon
                opacity: trayItem.passive && !mouseArea.containsMouse ? 0.55 : 1
            }

            StyledTooltip {
                anchorItem: trayItem
                text: trayItem.tooltipText
                requested: mouseArea.containsMouse && !menuPopup.visible
            }

            StyledMenu {
                id: menuPopup
                menuHandle: trayItem.modelData.menu
                anchorItem: trayItem

                onActionTriggered: TrayMenuState.currentMenu?.closeMenu()
                onDismissed: TrayMenuState.closed(menuPopup)
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton) {
                        if (trayItem.modelData.hasMenu)
                            TrayMenuState.open(menuPopup);
                    } else if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu) {
                        TrayMenuState.open(menuPopup);
                    } else {
                        trayItem.modelData.activate();
                    }
                }

                onWheel: wheel => {
                    const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                    const delta = horizontal ? wheel.angleDelta.x : wheel.angleDelta.y;
                    trayItem.modelData.scroll(delta, horizontal);
                    wheel.accepted = true;
                }
            }
        }
    }
}
