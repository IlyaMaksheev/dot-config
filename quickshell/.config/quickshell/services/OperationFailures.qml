pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var reported: ({})
    property string queuedSummary: ""
    property string queuedBody: ""

    function beginSession() {
        reported = ({});
    }

    function report(key, summary, body) {
        if (reported[key])
            return;
        const updated = Object.assign({}, reported);
        updated[key] = true;
        reported = updated;
        queuedSummary = summary;
        queuedBody = body;
        notifier.command = ["notify-send", "--app-name=Quickshell", summary, body];
        notifier.running = true;
    }

    Process {
        id: notifier
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Failed to send operation notification:", root.queuedSummary, exitCode, exitStatus);
        }
    }
}
