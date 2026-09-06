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
    property var moduleControls: expanded
        ? [logoutButton, sleepButton, rebootButton, shutdownButton, powerButton]
        : [powerButton]
    readonly property var primaryControl: powerButton
    property var adoptPointer: function(control) {}
    signal closeRequested()
    signal navigationChanged()

    function isActionControl(control) {
        return control === logoutButton || control === sleepButton || control === rebootButton || control === shutdownButton || control === powerButton;
    }

    function isExpandedActionControl(control) {
        return expanded && isActionControl(control);
    }

    function isSelectedControl(control) {
        return (selectedAction === "logout" && control === logoutButton)
            || (selectedAction === "hybrid-sleep" && control === sleepButton)
            || (selectedAction === "reboot" && control === rebootButton)
            || (selectedAction === "shutdown" && control === shutdownButton);
    }

    function actionName(action) {
        switch (action) {
        case "logout": return "Log out";
        case "hybrid-sleep": return "Hybrid sleep";
        case "reboot": return "Reboot";
        case "shutdown": return "Shut down";
        default: return "Power actions";
        }
    }

    function focusedAction() {
        if (selectedAction) return selectedAction;
        if (logoutButton.cursorActive) return "logout";
        if (sleepButton.cursorActive) return "hybrid-sleep";
        if (rebootButton.cursorActive) return "reboot";
        if (shutdownButton.cursorActive) return "shutdown";
        return "";
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
        navigationChanged();
        return true;
    }

    function escapePowerState() {
        if (cancelPending()) return true;
        if (expanded && !launchPending) {
            expanded = false;
            navigationChanged();
            return true;
        }
        return false;
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
        width: Math.max(0, actionViewport.x - Appearance.controlCenterGap)
        text: root.expanded && root.focusedAction()
            ? root.actionName(root.focusedAction()) + (root.selectedAction ? " selected · Esc cancels" : "")
            : "Control Center"
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

        Behavior on width { NumberAnimation { duration: Appearance.structuralAnimationDuration; easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic } }
        Behavior on opacity { NumberAnimation { duration: Appearance.structuralAnimationDuration } }

        Row {
            id: actionRow
            anchors.right: parent.right
            spacing: Appearance.controlCenterGap

            IconButton {
                id: logoutButton
                navigationRight: sleepButton
                enabled: root.expanded && !root.launchPending
                showFocusIndicator: false
                selected: root.selectedAction === "logout"
                icon: root.selectedAction === "logout" ? "󰍃 ✓" : "󰍃"
                accessibleStatus: root.selectedAction === "logout" ? "Logout selected; Escape cancels" : "Log out"
                onActivated: root.activate("logout")
                onHovered: root.adoptPointer(logoutButton)
            }
            IconButton {
                id: sleepButton
                navigationLeft: logoutButton
                navigationRight: rebootButton
                enabled: root.expanded && !root.launchPending
                showFocusIndicator: false
                selected: root.selectedAction === "hybrid-sleep"
                icon: root.selectedAction === "hybrid-sleep" ? "󰒲 ✓" : "󰒲"
                accessibleStatus: root.selectedAction === "hybrid-sleep" ? "Hybrid sleep selected; Escape cancels" : "Hybrid sleep"
                onActivated: root.activate("hybrid-sleep")
                onHovered: root.adoptPointer(sleepButton)
            }
            IconButton {
                id: rebootButton
                navigationLeft: sleepButton
                navigationRight: shutdownButton
                enabled: root.expanded && !root.launchPending
                showFocusIndicator: false
                destructive: true
                selected: root.selectedAction === "reboot"
                icon: root.selectedAction === "reboot" ? "󰜉 ✓" : "󰜉"
                accessibleStatus: root.selectedAction === "reboot" ? "Reboot selected; Escape cancels" : "Reboot"
                onActivated: root.activate("reboot")
                onHovered: root.adoptPointer(rebootButton)
            }
            IconButton {
                id: shutdownButton
                navigationLeft: rebootButton
                navigationRight: powerButton
                enabled: root.expanded && !root.launchPending
                showFocusIndicator: false
                destructive: true
                selected: root.selectedAction === "shutdown"
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
        navigationLeft: root.expanded ? shutdownButton : null
        accessibleStatus: root.expanded ? "Collapse power actions" : "Expand power actions"
        enabled: !root.launchPending && root.selectedAction === ""
        showFocusIndicator: !root.expanded
        onActivated: {
            root.expanded = !root.expanded;
            root.navigationChanged();
        }
        onHovered: root.adoptPointer(powerButton)
    }
}
