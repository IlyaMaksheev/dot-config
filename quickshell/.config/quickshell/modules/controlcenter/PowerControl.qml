import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root

    property bool effectiveVisible: true
    property int preferredHeight: Appearance.controlCenterHeaderHeight
    property bool panelVisible: false
    property bool expanded: false
    property string selectedAction: ""
    property bool launchPending: false
    property var moduleControls: [logoutButton, sleepButton, rebootButton, shutdownButton, powerButton]
    property var adoptPointer: function(control) {}
    signal closeRequested()
    signal navigationChanged()

    function isActionControl(control) {
        return control === logoutButton || control === sleepButton || control === rebootButton || control === shutdownButton || control === powerButton;
    }

    function isSelectedControl(control) {
        return (selectedAction === "logout" && control === logoutButton)
            || (selectedAction === "hybrid-sleep" && control === sleepButton)
            || (selectedAction === "reboot" && control === rebootButton)
            || (selectedAction === "shutdown" && control === shutdownButton);
    }

    function activate(action) {
        if (selectedAction !== "" || launchPending)
            return;
        selectedAction = action;
        selectionDelay.restart();
    }

    function cancelPending() {
        if (selectedAction === "" || launchPending)
            return false;
        selectionDelay.stop();
        selectedAction = "";
        expanded = false;
        navigationChanged();
        return true;
    }

    function collapse() {
        selectionDelay.stop();
        selectedAction = "";
        launchPending = false;
        if (expanded) {
            expanded = false;
            navigationChanged();
        }
    }

    function dispatchSelected() {
        const action = selectedAction;
        if (!action)
            return;
        selectedAction = "";
        launchPending = true;
        const accepted = action === "logout" ? Niri.logout() : Power.request(action);
        if (!accepted)
            launchFailed(action);
    }

    function launchFailed(action) {
        launchPending = false;
        expanded = true;
        if (action === "logout")
            OperationFailures.report("power-logout", "Logout failed", "Could not launch the Niri logout action.");
        navigationChanged();
    }

    onPanelVisibleChanged: if (!panelVisible) collapse()
    onExpandedChanged: navigationChanged()

    Timer {
        id: selectionDelay
        interval: Appearance.structuralDuration
        onTriggered: root.dispatchSelected()
    }

    Connections {
        target: Power
        function onLaunched(action) {
            if (root.launchPending) {
                root.launchPending = false;
                root.collapse();
                root.closeRequested();
            }
        }
        function onLaunchFailed(action) {
            if (root.launchPending)
                root.launchFailed(action);
        }
    }

    Connections {
        target: Niri
        function onLogoutLaunched() {
            if (root.launchPending) {
                root.launchPending = false;
                root.collapse();
                root.closeRequested();
            }
        }
        function onLogoutLaunchFailed() {
            if (root.launchPending)
                root.launchFailed("logout");
        }
    }

    SectionHeader {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "Control Center"
    }

    Item {
        id: actionViewport
        anchors.right: powerButton.left
        anchors.rightMargin: Appearance.controlCenterGap
        anchors.verticalCenter: parent.verticalCenter
        height: Appearance.controlCenterRowHeight
        width: root.expanded ? actionRow.implicitWidth : 0
        clip: true
        opacity: root.expanded ? 1 : 0

        Behavior on width { NumberAnimation { duration: Appearance.structuralAnimationDuration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Appearance.structuralAnimationDuration } }

        Row {
            id: actionRow
            anchors.right: parent.right
            spacing: Appearance.controlCenterGap

            IconButton {
                id: logoutButton
                visible: root.expanded
                enabled: !root.launchPending && root.selectedAction === ""
                icon: root.selectedAction === "logout" ? "󰍃 ✓" : "󰍃"
                accessibleStatus: root.selectedAction === "logout" ? "Logout selected; Escape cancels" : "Log out"
                onActivated: root.activate("logout")
                onHovered: root.adoptPointer(logoutButton)
            }
            IconButton {
                id: sleepButton
                visible: root.expanded
                enabled: !root.launchPending && root.selectedAction === ""
                icon: root.selectedAction === "hybrid-sleep" ? "󰒲 ✓" : "󰒲"
                accessibleStatus: root.selectedAction === "hybrid-sleep" ? "Hybrid sleep selected; Escape cancels" : "Hybrid sleep"
                onActivated: root.activate("hybrid-sleep")
                onHovered: root.adoptPointer(sleepButton)
            }
            IconButton {
                id: rebootButton
                visible: root.expanded
                enabled: !root.launchPending && root.selectedAction === ""
                destructive: true
                icon: root.selectedAction === "reboot" ? "󰜉 ✓" : "󰜉"
                accessibleStatus: root.selectedAction === "reboot" ? "Reboot selected; Escape cancels" : "Reboot"
                onActivated: root.activate("reboot")
                onHovered: root.adoptPointer(rebootButton)
            }
            IconButton {
                id: shutdownButton
                visible: root.expanded
                enabled: !root.launchPending && root.selectedAction === ""
                destructive: true
                icon: root.selectedAction === "shutdown" ? "󰐥 ✓" : "󰐥"
                accessibleStatus: root.selectedAction === "shutdown" ? "Shutdown selected; Escape cancels" : "Shut down"
                onActivated: root.activate("shutdown")
                onHovered: root.adoptPointer(shutdownButton)
            }
        }
    }

    IconButton {
        id: powerButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        icon: root.expanded ? "󰅖" : "󰐥"
        accessibleStatus: root.expanded ? "Collapse power actions" : "Expand power actions"
        enabled: !root.launchPending && root.selectedAction === ""
        onActivated: {
            root.expanded = !root.expanded;
            root.navigationChanged();
        }
        onHovered: root.adoptPointer(powerButton)
    }
}
