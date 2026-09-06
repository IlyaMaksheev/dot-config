pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var reported: ({})
    property var pendingNotifications: []
    property string activeSummary: ""
    property string activeBody: ""
    readonly property int maximumPendingNotifications: 16

    function beginSession() {
        reported = ({});
    }

    function report(key, summary, body) {
        if (reported[key])
            return;

        const updated = Object.assign({}, reported);
        updated[key] = true;
        reported = updated;

        if (pendingNotifications.length >= maximumPendingNotifications) {
            console.warn("Operation notification queue is full; not sending:", summary);
            return;
        }

        const pending = pendingNotifications.slice();
        pending.push({ summary: summary, body: body });
        pendingNotifications = pending;
        startNextNotification();
    }

    function startNextNotification() {
        if (notifier.running || pendingNotifications.length === 0)
            return;

        const pending = pendingNotifications.slice();
        const notification = pending.shift();
        pendingNotifications = pending;
        activeSummary = notification.summary;
        activeBody = notification.body;
        notifier.command = ["notify-send", "--app-name=Quickshell", activeSummary, activeBody];
        notifier.running = true;
    }

    function finishNotification(exitCode, exitStatus) {
        if (exitCode !== 0)
            console.warn("Failed to send operation notification:", activeSummary, exitCode, exitStatus);
        activeSummary = "";
        activeBody = "";
        startNextNotification();
    }

    Process {
        id: notifier
        onExited: (exitCode, exitStatus) => root.finishNotification(exitCode, exitStatus)
    }
}
