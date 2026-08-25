pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../services"
import "../../theme"

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

            Rectangle {
                id: panel
                visible: overlay.ownsPanel
                focus: overlay.ownsPanel
                width: Math.max(0, Math.min(480, Math.max(360, overlay.width / 4), overlay.width - Appearance.controlCenterEdgeGap * 2))
                height: Math.min(implicitHeight, Math.max(0, overlay.height - Appearance.barHeight - Appearance.controlCenterEdgeGap * 2))
                implicitHeight: 160
                color: Appearance.dark0_soft
                border.width: 3
                border.color: Appearance.dark_green_hard
                radius: 2

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

                Keys.onEscapePressed: event => {
                    root.close();
                    event.accepted = true;
                }

                Text {
                    anchors.centerIn: parent
                    text: "Control Center"
                    color: Appearance.light1
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontPixelSize
                }
            }
        }
    }
}
