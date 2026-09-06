pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.ready ? sink.audio : null
    readonly property bool available: Pipewire.ready && sink !== null && sink.ready && audio !== null
    readonly property real volume: available ? Math.max(0, Math.min(1, audio.volume)) : 0
    readonly property bool muted: available && audio.muted
    property bool requestPending: false
    property string requestKind: ""
    property real requestedVolume: 0
    property bool requestedMuted: false
    property var requestedSink: null

    function requestVolume(value) {
        if (!available)
            return;
        const normalized = Math.max(0, Math.min(1, value));
        requestedSink = sink;
        requestedVolume = normalized;
        requestKind = "volume";
        requestPending = true;
        audio.volume = normalized;
        confirmation.restart();
    }

    function requestMuteToggle() {
        if (!available)
            return;
        requestedSink = sink;
        requestedMuted = !audio.muted;
        requestKind = "mute";
        requestPending = true;
        audio.muted = requestedMuted;
        confirmation.restart();
    }

    function reconcile() {
        if (!requestPending || requestedSink !== sink) {
            requestPending = false;
            confirmation.stop();
            return;
        }
        const confirmed = requestKind === "volume"
            ? audio !== null && Math.abs(Math.max(0, Math.min(1, audio.volume)) - requestedVolume) < 0.005
            : audio !== null && audio.muted === requestedMuted;
        if (confirmed) {
            requestPending = false;
            confirmation.stop();
        }
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            root.requestPending = false;
            confirmation.stop();
        }
    }

    Connections {
        target: root.audio
        ignoreUnknownSignals: true
        function onVolumesChanged() { root.reconcile(); }
        function onMutedChanged() { root.reconcile(); }
    }

    Timer {
        id: confirmation
        interval: 1200
        onTriggered: {
            root.reconcile();
            if (!root.requestPending)
                return;
            const kind = root.requestKind;
            root.requestPending = false;
            OperationFailures.report("audio-" + kind, "Audio change failed", "The default output did not confirm the requested " + kind + " change.");
        }
    }
}
