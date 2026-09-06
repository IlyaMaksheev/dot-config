pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Set this to a kernel backlight device name for a retained hardware preference.
    property string preferredDevice: ""
    property string selectedDevice: ""
    property bool available: false
    property bool writable: false
    property int current: 0
    property int maximum: 0
    readonly property real value: available && maximum > 0 ? current / maximum : 0
    property bool panelVisible: false
    property bool refreshPending: false
    property bool refreshAgain: false
    property bool writePending: false
    property var candidates: []
    property int probeIndex: 0
    property string readDevice: ""

    function setPanelVisible(visible) {
        panelVisible = visible;
        if (visible)
            refresh();
    }

    function refresh() {
        if (refreshPending || writePending) {
            refreshAgain = true;
            return;
        }
        refreshPending = true;
        listProcess.running = true;
    }

    function finishList(exitCode) {
        candidates = [];
        if (exitCode === 0) {
            const names = listOutput.text.split("\n").map(name => name.trim()).filter(name => /^[A-Za-z0-9_.:-]+$/.test(name));
            names.sort();
            for (const name of names)
                candidates.push({ name: name, type: "raw" });
        }
        probeIndex = 0;
        probeNext();
    }

    function probeNext() {
        if (probeIndex >= candidates.length) {
            selectAndRead();
            return;
        }
        typeProcess.command = ["cat", "/sys/class/backlight/" + candidates[probeIndex].name + "/type"];
        typeProcess.running = true;
    }

    function finishType(exitCode) {
        if (exitCode === 0) {
            const type = typeOutput.text.trim().toLowerCase();
            candidates[probeIndex].type = ["firmware", "platform", "raw"].indexOf(type) >= 0 ? type : "raw";
        }
        probeIndex++;
        probeNext();
    }

    function selectAndRead() {
        const preferred = preferredDevice.trim();
        let selected = null;
        if (preferred.length)
            selected = candidates.find(candidate => candidate.name === preferred);
        if (!selected && candidates.length) {
            const rank = { firmware: 0, platform: 1, raw: 2 };
            candidates.sort((left, right) => rank[left.type] - rank[right.type] || left.name.localeCompare(right.name));
            selected = candidates[0];
        }
        if (!selected) {
            selectedDevice = "";
            available = false;
            writable = false;
            current = 0;
            maximum = 0;
            finishRefresh();
            return;
        }
        readDevice = selected.name;
        readProcess.command = ["brightnessctl", "--class=backlight", "--device=" + readDevice, "--machine-readable", "info"];
        readProcess.running = true;
    }

    function finishRead(exitCode) {
        const fields = readOutput.text.trim().split(",");
        const readCurrent = fields.length >= 5 ? Number(fields[2]) : NaN;
        const readMaximum = fields.length >= 5 ? Number(fields[4]) : NaN;
        if (exitCode === 0 && Number.isFinite(readCurrent) && Number.isFinite(readMaximum) && readMaximum > 0) {
            selectedDevice = readDevice;
            current = Math.max(0, Math.min(readMaximum, readCurrent));
            maximum = readMaximum;
            available = true;
            writeTest.command = ["test", "-w", "/sys/class/backlight/" + readDevice + "/brightness"];
            writeTest.running = true;
        } else {
            if (selectedDevice === readDevice) {
                available = false;
                writable = false;
            }
            finishRefresh();
        }
    }

    function requestValue(normalized) {
        if (!available || !writable || writePending)
            return;
        const target = Math.max(maximum >= 1 ? 1 : 0, Math.min(maximum, Math.round(Math.max(0, Math.min(1, normalized)) * maximum)));
        writePending = true;
        readDevice = selectedDevice;
        writeProcess.command = ["brightnessctl", "--class=backlight", "--device=" + readDevice, "set", String(target)];
        writeProcess.running = true;
    }

    function finishRefresh() {
        refreshPending = false;
        if (refreshAgain) {
            refreshAgain = false;
            refresh();
        }
    }

    Process {
        id: listProcess
        command: ["find", "/sys/class/backlight", "-mindepth", "1", "-maxdepth", "1", "-printf", "%f\\n"]
        stdout: StdioCollector { id: listOutput }
        onExited: exitCode => root.finishList(exitCode)
    }
    Process {
        id: typeProcess
        stdout: StdioCollector { id: typeOutput }
        onExited: exitCode => root.finishType(exitCode)
    }
    Process {
        id: readProcess
        stdout: StdioCollector { id: readOutput }
        onExited: exitCode => root.finishRead(exitCode)
    }
    Process {
        id: writeTest
        onExited: exitCode => { root.writable = exitCode === 0; root.finishRefresh(); }
    }
    Process {
        id: writeProcess
        onExited: exitCode => {
            root.writePending = false;
            if (exitCode !== 0)
                OperationFailures.report("backlight-write", "Brightness change failed", "The selected internal backlight did not accept the requested brightness.");
            // Confirm against the same device even after failure; selection changes only on discovery.
            root.refreshPending = true;
            readProcess.command = ["brightnessctl", "--class=backlight", "--device=" + root.readDevice, "--machine-readable", "info"];
            readProcess.running = true;
        }
    }
    Timer { interval: 2500; running: root.panelVisible; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
