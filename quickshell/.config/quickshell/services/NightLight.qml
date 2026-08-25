pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int nightThreshold: 5250
    property bool available: false
    property bool enabled: false
    property int temperature: 0
    property bool refreshPending: false
    property bool togglePending: false
    property bool refreshAgain: false

    function refresh() {
        if (refreshPending) {
            refreshAgain = true;
            return;
        }
        refreshPending = true;
        refreshProcess.running = true;
    }

    function requestToggle() {
        if (!available || togglePending)
            return;
        togglePending = true;
        toggleProcess.running = true;
    }

    function finishRefresh(exitCode) {
        const match = refreshOutput.text.trim().match(/^q\s+(\d+)$/);
        if (exitCode === 0 && match) {
            const confirmedTemperature = Number(match[1]);
            temperature = confirmedTemperature;
            enabled = confirmedTemperature < nightThreshold;
            available = true;
        } else {
            available = false;
            OperationFailures.report("night-light-refresh", "Night Light unavailable", "The wl-gammarelay D-Bus state could not be refreshed.");
        }
        refreshPending = false;
        if (refreshAgain) {
            refreshAgain = false;
            refresh();
        }
    }

    Process {
        id: refreshProcess
        command: ["busctl", "--user", "get-property", "rs.wl-gammarelay", "/", "rs.wl.gammarelay", "Temperature"]
        stdout: StdioCollector { id: refreshOutput }
        onExited: exitCode => root.finishRefresh(exitCode)
    }

    Process {
        id: toggleProcess
        command: [Quickshell.env("HOME") + "/.config/niri/scripts/night-color.sh", "toggle"]
        onExited: exitCode => {
            root.togglePending = false;
            if (exitCode !== 0)
                OperationFailures.report("night-light-toggle", "Night Light change failed", "The Night Light script did not complete successfully.");
            root.refresh();
        }
    }
}
