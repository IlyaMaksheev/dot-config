pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../services"
import "../../theme"
import "../../components"

Singleton {
    id: root

    property string targetOutput: ""
    property bool isOpen: false

    function screenForOutput(outputName) {
        if (!outputName)
            return null;

        for (const screen of Quickshell.screens) {
            if (screen.name === outputName)
                return screen;
        }

        return null;
    }

    function resolvedOutput(outputName) {
        return outputName || Niri.focusedOutputName();
    }

    function open(outputName) {
        const output = root.resolvedOutput(outputName);
        if (!root.screenForOutput(output)) {
            root.close();
            return;
        }

        PopupCoordinator.activate(root);

        OperationFailures.beginSession();
        root.targetOutput = output;
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
        root.targetOutput = "";
        PopupCoordinator.release(root);
    }

    Component.onDestruction: PopupCoordinator.release(root)

    function toggle(outputName) {
        if (root.isOpen) {
            root.close();
            return;
        }

        root.open(outputName);
    }

    Timer {
        interval: 250
        repeat: true
        running: root.isOpen
        onTriggered: {
            if (!root.screenForOutput(root.targetOutput))
                root.close();
        }
    }

    IpcHandler {
        target: "controlCenter"

        function open(): void {
            root.open("");
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle("");
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property bool ownsPanel: root.isOpen && root.targetOutput === modelData.name

            onOwnsPanelChanged: {
                if (ownsPanel)
                    Qt.callLater(() => content.forceActiveFocus(Qt.PopupFocusReason));
            }

            screen: modelData
            visible: root.isOpen
            color: "transparent"
            exclusiveZone: 0
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            WlrLayershell.layer: WlrLayer.Overlay
            // The owner holds keyboard focus. Other output overlays remain pointer-focusable
            // so their first outside click is delivered instead of only transferring Niri focus.
            WlrLayershell.keyboardFocus: ownsPanel
                ? WlrKeyboardFocus.Exclusive
                : root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            PanelSurface {
                id: panel
                visible: overlay.ownsPanel
                focus: overlay.ownsPanel
                focused: overlay.ownsPanel && content.activeFocus
                width: Math.max(0, Math.min(480, Math.max(360, overlay.width / 4), overlay.width - Appearance.controlCenterEdgeGap * 2))
                readonly property real availableHeight: Math.max(0, overlay.height - Appearance.barHeight - Appearance.controlCenterEdgeGap * 2)
                height: Math.min(implicitHeight, availableHeight)
                implicitHeight: content.implicitHeight + Appearance.controlCenterPadding * 2 + Appearance.controlCenterBorderWidth * 2

                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: Appearance.barHeight + Appearance.controlCenterEdgeGap
                    rightMargin: Appearance.controlCenterEdgeGap
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                Flickable {
                    id: viewport
                    anchors.fill: parent
                    anchors.margins: Appearance.controlCenterBorderWidth
                    contentWidth: width
                    contentHeight: content.implicitHeight + Appearance.controlCenterPadding * 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    function reveal(item) {
                        const point = item.mapToItem(content, 0, 0);
                        if (point.y < contentY)
                            contentY = Math.max(0, point.y - Appearance.controlCenterPadding);
                        else if (point.y + item.height > contentY + height)
                            contentY = Math.min(contentHeight - height, point.y + item.height - height + Appearance.controlCenterPadding);
                    }

                    ControlCenterContent {
                        id: content
                        x: Appearance.controlCenterPadding
                        y: Appearance.controlCenterPadding
                        width: viewport.width - Appearance.controlCenterPadding * 2
                        panelVisible: overlay.ownsPanel
                        ensureVisible: item => viewport.reveal(item)
                        onCloseRequested: root.close()
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: viewport.contentHeight > viewport.height + 0.5 && (viewport.moving || panelHover.hovered || content.cursorVisible)
                            ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        width: 3
                    }
                }

                HoverHandler {
                    id: panelHover
                    property bool enteredPanel: false
                    onHoveredChanged: {
                        if (hovered)
                            enteredPanel = true;
                        else if (enteredPanel) {
                            enteredPanel = false;
                            content.clearCursor();
                        }
                    }
                }
            }
        }
    }
}
