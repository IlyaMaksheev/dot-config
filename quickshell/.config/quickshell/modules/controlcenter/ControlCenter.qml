pragma Singleton

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
    property bool primingFocus: false

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

        if (TrayMenuState.currentMenu)
            TrayMenuState.currentMenu.closeMenu();

        root.targetOutput = output;
        root.isOpen = true;
        root.primingFocus = true;
        focusPrime.restart();
    }

    function close() {
        focusPrime.stop();
        root.primingFocus = false;
        root.isOpen = false;
        root.targetOutput = "";
    }

    function toggle(outputName) {
        if (root.isOpen) {
            root.close();
            return;
        }

        root.open(outputName);
    }

    Timer {
        id: focusPrime
        interval: 80
        onTriggered: root.primingFocus = false
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

    Connections {
        target: TrayMenuState
        function onCurrentMenuChanged() {
            if (root.isOpen && TrayMenuState.currentMenu)
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
            WlrLayershell.keyboardFocus: ownsPanel
                ? (root.primingFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
                : WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            PanelSurface {
                id: panel
                visible: overlay.ownsPanel
                focus: overlay.ownsPanel
                width: Math.max(0, Math.min(480, Math.max(360, overlay.width / 4), overlay.width - Appearance.controlCenterEdgeGap * 2))
                height: Math.min(implicitHeight, Math.max(0, overlay.height - Appearance.barHeight - Appearance.controlCenterEdgeGap * 2))
                implicitHeight: content.implicitHeight + Appearance.controlCenterPadding * 2

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
                        ensureVisible: item => viewport.reveal(item)
                        onCloseRequested: root.close()
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: viewport.contentHeight > viewport.height && (viewport.moving || panelHover.containsMouse || content.cursorVisible)
                            ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        width: 3
                    }
                }

                HoverHandler { id: panelHover }
            }
        }
    }
}
