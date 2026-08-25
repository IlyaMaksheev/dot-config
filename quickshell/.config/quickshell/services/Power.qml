pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string pendingAction: ""
    signal launched(string action)
    signal launchFailed(string action)

    function request(action) {
        if (pendingAction !== "")
            return false;

        const commands = {
            "hybrid-sleep": ["systemctl", "hybrid-sleep"],
            "reboot": ["systemctl", "reboot"],
            "shutdown": ["systemctl", "poweroff"]
        };
        if (!commands[action])
            return false;

        pendingAction = action;
        command.command = commands[action];
        command.running = true;
        launchCheck.restart();
        return true;
    }

    function finishLaunchCheck() {
        const action = pendingAction;
        if (!action)
            return;
        if (command.running) {
            // onRunningChanged normally acknowledges this synchronously; keep this
            // branch for backends that defer that notification.
            pendingAction = "";
            launched(action);
        } else {
            pendingAction = "";
            OperationFailures.report("power-" + action, "Power action failed", "Could not launch " + action + ".");
            launchFailed(action);
        }
    }

    Timer {
        id: launchCheck
        interval: 0
        onTriggered: root.finishLaunchCheck()
    }

    Process {
        id: command
        onRunningChanged: {
            if (running && root.pendingAction !== "") {
                const action = root.pendingAction;
                root.pendingAction = "";
                root.launched(action);
            }
        }
        onExited: (exitCode, exitStatus) => {
            // A process that reached onExited was launched successfully. Subsequent
            // systemctl failure is logged, but cannot safely reopen a closing panel.
            if (exitCode !== 0)
                console.warn("Power action exited unsuccessfully:", exitCode, exitStatus);
        }
    }
}
