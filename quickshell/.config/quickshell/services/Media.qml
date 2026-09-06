pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Mpris

Singleton {
    id: root

    // Opt-in transaction diagnostics, without titles, URLs, or metadata.
    readonly property bool seekDiagnostics: Quickshell.env("QS_MEDIA_SEEK_DEBUG") === "1"
    property int seekDiagnosticSamples: 0

    readonly property var players: Mpris.players.values || []
    property var selectedPlayer: null
    property int trackRevision: 0

    // Last backend-confirmed values belong only to interactionKey and survive
    // transient MPRIS position/length support loss.
    property string reliableKey: ""
    property bool hasReliablePosition: false
    property real reliablePosition: 0
    property real reliablePositionAtMs: 0
    property real reliableDuration: 0
    property bool reliablePositionFromReadback: false
    property bool seekWriteActive: false
    property bool nativePositionSpeculative: false
    property real positionClockMs: Date.now()

    // One service-owned seek session and one serialized command.
    property bool seekSessionActive: false
    property bool seekSessionStaged: false
    property string seekSessionKey: ""
    property real seekDisplayPosition: 0
    property real seekDisplayDuration: 0
    property real seekDisplayAtMs: 0
    property bool seekPending: false
    property bool seekFailed: false
    property int seekGeneration: 0
    property int inFlightGeneration: 0
    property string inFlightKey: ""
    property real inFlightTarget: 0
    property real inFlightSentAtMs: 0
    property bool inFlightPlaying: false
    property real inFlightBaseline: 0
    property int inFlightObservationRevision: 0
    property int positionObservationRevision: 0
    property bool seekAwaitingLateConfirmation: false
    property real queuedTarget: NaN

    // Centralized allowance for MPRIS refresh latency and player keyframe
    // quantization. It remains target-distance based, never direction based.
    readonly property real seekConfirmationTolerance: reliableDuration > 0
        ? Math.max(1.25, Math.min(3.0, reliableDuration * 0.005)) : 1.5

    readonly property bool available: selectedPlayer !== null
    readonly property bool playing: available && selectedPlayer.playbackState === MprisPlaybackState.Playing
    readonly property bool paused: available && selectedPlayer.playbackState === MprisPlaybackState.Paused
    readonly property bool canPrevious: available && selectedPlayer.canControl && selectedPlayer.canGoPrevious
    readonly property bool canNext: available && selectedPlayer.canControl && selectedPlayer.canGoNext
    readonly property bool canToggle: available && selectedPlayer.canControl && selectedPlayer.canTogglePlaying
    readonly property bool relativeSeekAvailable: available && selectedPlayer.canControl && selectedPlayer.canSeek
    readonly property string playerKey: available
        ? String(selectedPlayer.dbusName) + "|" + String(selectedPlayer.uniqueId) : ""
    readonly property string interactionKey: playerKey + "|" + trackRevision
    readonly property bool currentPositionReadable: available && selectedPlayer.positionSupported
        && Number.isFinite(selectedPlayer.position) && selectedPlayer.position >= 0
    readonly property bool currentDurationReadable: available && selectedPlayer.lengthSupported
        && Number.isFinite(selectedPlayer.length) && selectedPlayer.length > 0
    readonly property bool progressReadable: reliableKey === interactionKey && hasReliablePosition
    readonly property bool absoluteSeekAvailable: relativeSeekAvailable && reliableKey === interactionKey
        && reliableDuration > 0
    readonly property real progressPosition: seekSessionActive || seekPending
        ? seekDisplayPosition : progressReadable ? estimatedReliablePosition(positionClockMs) : 0
    readonly property real progressDuration: seekSessionActive || seekPending
        ? seekDisplayDuration : reliableKey === interactionKey ? reliableDuration : 0
    readonly property real seekStep: progressDuration > 0 ? progressDuration * 0.01 : 5
    readonly property string title: available && selectedPlayer.trackTitle ? selectedPlayer.trackTitle : (available ? selectedPlayer.identity : "")
    readonly property string artist: available ? selectedPlayer.trackArtist : ""
    readonly property string artwork: available ? selectedPlayer.trackArtUrl : ""

    function traceSeek(event, details) {
        if (!seekDiagnostics)
            return;
        console.log("MEDIA_SEEK", JSON.stringify({
            ms: Date.now(), event: event, key: interactionKey,
            generation: inFlightGeneration, staged: seekSessionStaged,
            pending: seekPending, playing: playing,
            native: available ? selectedPlayer.position : null,
            rate: available ? selectedPlayer.rate : null,
            reliable: reliablePosition, preview: seekDisplayPosition,
            target: inFlightTarget, details: details || {}
        }));
    }

    function traceSeekSample(event, details) {
        // Never log perpetual polling; bound motion/native samples per session.
        if (seekDiagnostics && (seekSessionActive || seekPending) && seekDiagnosticSamples < 24) {
            seekDiagnosticSamples++;
            traceSeek(event, details);
        }
    }

    function rank(player) {
        if (player.playbackState === MprisPlaybackState.Playing)
            return 0;
        if (player.playbackState === MprisPlaybackState.Paused)
            return 1;
        return 2;
    }

    function reconcileSelection() {
        if (selectedPlayer && players.indexOf(selectedPlayer) >= 0)
            return;
        const candidates = players.slice().sort((left, right) => {
            const rankDifference = rank(left) - rank(right);
            return rankDifference !== 0 ? rankDifference
                : String(left.dbusName).localeCompare(String(right.dbusName));
        });
        selectedPlayer = candidates.length ? candidates[0] : null;
    }

    function clearTrackState() {
        reliableKey = interactionKey;
        hasReliablePosition = false;
        reliablePosition = 0;
        reliablePositionAtMs = 0;
        reliablePositionFromReadback = false;
        nativePositionSpeculative = false;
        reliableDuration = 0;
        cancelSeekSession();
    }

    function refreshReliableState(freshPositionObservation) {
        if (!available)
            return;
        if (reliableKey !== interactionKey)
            clearTrackState();
        const now = Date.now();
        if (freshPositionObservation === true)
            traceSeekSample("native-observation", {position: selectedPlayer.position});
        positionClockMs = now;
        // A getter read is extrapolated native cache, not a D-Bus refresh.
        // Do not overwrite explicit readback with a cache missing Seeked.
        if (currentPositionReadable && ((!reliablePositionFromReadback && !nativePositionSpeculative)
                || freshPositionObservation === true)) {
            if (freshPositionObservation === true) {
                positionObservationRevision++;
                reliablePositionFromReadback = false;
                nativePositionSpeculative = false;
            }
            reliablePosition = selectedPlayer.position;
            reliablePositionAtMs = now;
            hasReliablePosition = true;
            if (seekFailed && freshPositionObservation === true)
                seekFailed = false;
        }
        if (currentDurationReadable)
            reliableDuration = selectedPlayer.length;
        reconcileInFlight(now);
    }

    function estimatedReliablePosition(now) {
        if (!progressReadable)
            return 0;
        const elapsed = playing ? Math.max(0, (now - reliablePositionAtMs) / 1000) : 0;
        const candidate = reliablePosition + elapsed;
        return reliableDuration > 0 ? Math.min(reliableDuration, Math.max(0, candidate)) : Math.max(0, candidate);
    }

    function clampSeek(candidate) {
        const bounded = Math.max(0, candidate);
        return seekDisplayDuration > 0 ? Math.min(seekDisplayDuration, bounded) : Math.min(24 * 60 * 60, bounded);
    }

    function beginSeekSession(staged) {
        if (!relativeSeekAvailable || !progressReadable)
            return false;
        seekDiagnosticSamples = 0;
        seekSessionActive = true;
        seekSessionStaged = staged === true;
        seekSessionKey = interactionKey;
        seekDisplayDuration = reliableDuration;
        const now = Date.now();
        seekDisplayPosition = estimatedReliablePosition(now);
        seekDisplayAtMs = now;
        seekFailed = false;
        traceSeek("begin", {baseline: seekDisplayPosition, duration: seekDisplayDuration});
        return true;
    }

    function endSeekSession(commit) {
        const shouldCommit = seekSessionActive && commit && Number.isFinite(queuedTarget);
        if (seekSessionActive)
            traceSeek(commit ? "commit" : "cancel", {queued: Number.isFinite(queuedTarget) ? queuedTarget : null});
        seekSessionActive = false;
        seekSessionStaged = false;
        if (shouldCommit)
            dispatchQueued();
        // Pending confirmation deliberately remains service-owned after UI exit.
        if (!seekPending && inFlightGeneration === 0) {
            seekSessionKey = "";
            queuedTarget = NaN;
        }
    }

    function cancelSeekSession() {
        if (seekSessionActive || seekPending)
            traceSeek("invalidate", {sessionKey: seekSessionKey, flightKey: inFlightKey});
        seekSessionActive = false;
        seekSessionStaged = false;
        seekSessionKey = "";
        seekPending = false;
        seekFailed = false;
        seekAwaitingLateConfirmation = false;
        inFlightGeneration = 0;
        inFlightKey = "";
        queuedTarget = NaN;
        seekDispatch.stop();
        seekConfirmationDeadline.stop();
        seekLateDeadline.stop();
    }

    function adjustSeek(direction) {
        if (!seekSessionActive || seekSessionKey !== interactionKey || !relativeSeekAvailable)
            return false;
        advanceSeekClock();
        seekDisplayPosition = clampSeek(seekDisplayPosition + (direction < 0 ? -seekStep : seekStep));
        seekDisplayAtMs = Date.now();
        queuedTarget = seekDisplayPosition;
        seekFailed = false;
        traceSeekSample("preview-step", {direction: direction, queued: queuedTarget});
        if (!seekSessionStaged)
            seekDispatch.restart();
        return true;
    }

    function seekFraction(fraction) {
        if (!absoluteSeekAvailable || !Number.isFinite(fraction))
            return false;
        if (!seekSessionActive && !beginSeekSession(false))
            return false;
        seekDisplayPosition = clampSeek(Math.max(0, Math.min(1, fraction)) * reliableDuration);
        seekDisplayAtMs = Date.now();
        queuedTarget = seekDisplayPosition;
        seekFailed = false;
        traceSeekSample("preview-pointer", {fraction: fraction, queued: queuedTarget});
        seekDispatch.restart();
        return true;
    }

    function wheelSeek(direction) {
        if (!absoluteSeekAvailable)
            return false;
        const temporarySession = !seekSessionActive;
        if (temporarySession && !beginSeekSession(false))
            return false;
        const accepted = adjustSeek(direction);
        if (temporarySession)
            endSeekSession(true);
        return accepted;
    }

    function dispatchQueued() {
        seekDispatch.stop();
        if (inFlightGeneration !== 0 || !Number.isFinite(queuedTarget))
            return;
        if (seekSessionKey !== interactionKey || !relativeSeekAvailable || !progressReadable) {
            queuedTarget = NaN;
            return;
        }
        const now = Date.now();
        const target = queuedTarget;
        queuedTarget = NaN;
        const baseline = estimatedReliablePosition(now);
        const offset = target - baseline;
        if (Math.abs(offset) < 0.01) {
            traceSeek("skip-negligible", {target: target, baseline: baseline, offset: offset});
            return;
        }
        const generation = ++seekGeneration;
        inFlightGeneration = generation;
        inFlightKey = interactionKey;
        inFlightTarget = target;
        inFlightSentAtMs = now;
        inFlightPlaying = playing;
        inFlightBaseline = baseline;
        inFlightObservationRevision = positionObservationRevision;
        seekAwaitingLateConfirmation = false;
        seekPending = true;
        const absolute = absoluteSeekAvailable && currentPositionReadable;
        traceSeek("dispatch", {target: target, baseline: baseline, offset: offset,
            method: absolute ? "position" : "seek"});
        try {
            if (absolute) {
                // MediaSession seekforward/backward handlers may implement fixed
                // steps. A timeline target needs the native SetPosition path.
                // Its synchronous cache write is optimistic, not an ACK.
                nativePositionSpeculative = true;
                seekWriteActive = true;
                selectedPlayer.position = target;
            } else {
                selectedPlayer.seek(offset);
            }
            seekConfirmationDeadline.restart();
        } catch (error) {
            console.warn("MPRIS seek failed:", error);
            failInFlight(generation, "The player did not accept the seek request.");
        } finally {
            seekWriteActive = false;
        }
    }

    function requestSeekReadback() {
        if (inFlightGeneration === 0 || inFlightKey !== interactionKey || seekReadback.running)
            return;
        // Fallback only: an actual native response outranks a contradictory
        // property getter (Firefox can temporarily return zero while playing).
        if (positionObservationRevision > inFlightObservationRevision && !reliablePositionFromReadback)
            return;
        seekReadback.generation = inFlightGeneration;
        seekReadback.key = interactionKey;
        // Quickshell 0.3 has no public native position refresh. Some players
        // (VLC while paused) accept Seek without emitting Seeked. Only query
        // during the existing bounded transaction; never synthesize an ACK.
        seekReadback.command = ["busctl", "--user", "--timeout=0.5", "get-property",
            String(selectedPlayer.dbusName), "/org/mpris/MediaPlayer2",
            "org.mpris.MediaPlayer2.Player", "Position"];
        seekReadback.running = true;
    }

    function finishSeekReadback(exitCode) {
        if (seekReadback.generation !== inFlightGeneration || seekReadback.key !== interactionKey)
            return;
        if (positionObservationRevision > inFlightObservationRevision && !reliablePositionFromReadback)
            return;
        const match = seekReadbackOutput.text.trim().match(/^x\s+(\d+)$/);
        if (exitCode !== 0 || !match) {
            traceSeekSample("readback-unavailable", {exitCode: exitCode, typedPosition: !!match});
            return;
        }
        const position = Number(match[1]) / 1000000;
        if (!Number.isFinite(position) || position < 0)
            return;
        const now = Date.now();
        reliablePosition = position;
        reliablePositionAtMs = now;
        reliablePositionFromReadback = true;
        hasReliablePosition = true;
        positionClockMs = now;
        positionObservationRevision++;
        traceSeekSample("readback-observation", {position: position});
        reconcileInFlight(now);
    }

    function reconcileInFlight(now) {
        if (inFlightGeneration === 0 || inFlightKey !== interactionKey || !progressReadable)
            return;
        // A value cached before dispatch cannot acknowledge the command.
        if (positionObservationRevision <= inFlightObservationRevision)
            return;
        const expected = expectedInFlightPosition(now);
        if (Math.abs(reliablePosition - expected) > seekConfirmationTolerance)
            return;
        traceSeek("ack", {position: reliablePosition, expected: expected,
            error: reliablePosition - expected, readback: reliablePositionFromReadback});
        const generation = inFlightGeneration;
        inFlightGeneration = 0;
        inFlightKey = "";
        seekConfirmationDeadline.stop();
        seekLateDeadline.stop();
        seekAwaitingLateConfirmation = false;
        seekPending = false;
        seekFailed = false;
        seekDisplayPosition = reliablePosition;
        seekDisplayAtMs = now;
        if (Number.isFinite(queuedTarget))
            dispatchQueued();
        else if (!seekSessionActive)
            seekSessionKey = "";
    }

    function expectedInFlightPosition(now) {
        return inFlightTarget + (inFlightPlaying
            ? Math.max(0, (now - inFlightSentAtMs) / 1000) : 0);
    }

    function naturalInFlightPosition(now) {
        return inFlightBaseline + (inFlightPlaying
            ? Math.max(0, (now - inFlightSentAtMs) / 1000) : 0);
    }

    function observedSeekWasIgnored(now) {
        if (positionObservationRevision <= inFlightObservationRevision || !progressReadable)
            return false;
        const targetDistance = Math.abs(reliablePosition - expectedInFlightPosition(now));
        const naturalDistance = Math.abs(reliablePosition - naturalInFlightPosition(now));
        return targetDistance > seekConfirmationTolerance
            && naturalDistance <= seekConfirmationTolerance;
    }

    function beginLateConfirmation(generation) {
        if (generation !== inFlightGeneration)
            return;
        const now = Date.now();
        reconcileInFlight(now);
        if (generation !== inFlightGeneration)
            return;
        traceSeek("confirmation-deadline", {expected: expectedInFlightPosition(now),
            observationRevision: positionObservationRevision, sentRevision: inFlightObservationRevision});
        seekAwaitingLateConfirmation = true;
        seekLateDeadline.restart();
    }

    function finishConfirmation(generation) {
        if (generation !== inFlightGeneration)
            return;
        const now = Date.now();
        reconcileInFlight(now);
        if (generation !== inFlightGeneration)
            return;
        const ignored = observedSeekWasIgnored(now);
        failInFlight(generation, ignored
            ? "The player continued on its pre-seek playback trajectory."
            : "The player did not confirm the requested position.");
    }

    function failInFlight(generation, description) {
        if (generation !== inFlightGeneration)
            return;
        traceSeek("failure", {reason: description, expected: expectedInFlightPosition(Date.now()),
            observationRevision: positionObservationRevision, sentRevision: inFlightObservationRevision});
        inFlightGeneration = 0;
        inFlightKey = "";
        seekConfirmationDeadline.stop();
        seekLateDeadline.stop();
        seekAwaitingLateConfirmation = false;
        seekPending = false;
        seekFailed = true;
        queuedTarget = NaN;
        if (progressReadable) {
            seekDisplayPosition = estimatedReliablePosition(Date.now());
            seekDisplayDuration = reliableDuration;
        }
        OperationFailures.report("mpris-seek-unconfirmed", "Media seek not confirmed", description);
        if (!seekSessionActive)
            seekSessionKey = "";
    }

    function advanceSeekClock() {
        const now = Date.now();
        if ((seekSessionActive || seekPending) && !seekSessionStaged
                && playing && seekDisplayAtMs > 0) {
            seekDisplayPosition = clampSeek(seekDisplayPosition + Math.max(0, (now - seekDisplayAtMs) / 1000));
            if (Number.isFinite(queuedTarget))
                queuedTarget = seekDisplayPosition;
        }
        seekDisplayAtMs = now;
    }

    function invoke(capable, operation, failureKey, description) {
        if (!capable || !selectedPlayer)
            return false;
        try {
            operation();
            return true;
        } catch (error) {
            console.warn("MPRIS action failed:", error);
            OperationFailures.report(failureKey, "Media action failed", description);
            return false;
        }
    }

    function previous() { invoke(canPrevious, () => selectedPlayer.previous(), "mpris-previous", "The player did not accept the previous-track request."); }
    function next() { invoke(canNext, () => selectedPlayer.next(), "mpris-next", "The player did not accept the next-track request."); }
    function togglePlaying() { invoke(canToggle, () => selectedPlayer.togglePlaying(), "mpris-toggle", "The player did not accept the play/pause request."); }

    function observeNativePosition(key, generation) {
        // A callback queued before dispatch must not sample the setter's cache.
        if (key === interactionKey && generation === seekGeneration)
            refreshReliableState(true);
    }

    onPlayersChanged: reconcileSelection()
    onSelectedPlayerChanged: {
        trackRevision++;
        clearTrackState();
        refreshReliableState();
    }
    Component.onCompleted: reconcileSelection()

    Connections {
        target: root.selectedPlayer
        ignoreUnknownSignals: true
        function onPlaybackStateChanged() { root.refreshReliableState(false); }
        function onPositionChanged() {
            if (root.seekWriteActive) {
                root.traceSeekSample("optimistic-native-write", {});
                return;
            }
            // Native MprisPlayer emits before and after updating its timestamp.
            // Observe the settled value, not the intermediate double-offset one.
            Qt.callLater(root.observeNativePosition, root.interactionKey, root.seekGeneration);
        }
        function onTrackChanged() {
            root.trackRevision++;
            root.clearTrackState();
            root.refreshReliableState(false);
        }
        function onLengthChanged() { root.refreshReliableState(false); }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.playing || root.seekSessionActive || root.seekPending
        onTriggered: {
            root.advanceSeekClock();
            if (root.currentPositionReadable)
                root.refreshReliableState(false);
        }
    }
    Process {
        id: seekReadback
        property int generation: 0
        property string key: ""
        stdout: StdioCollector { id: seekReadbackOutput }
        onExited: exitCode => root.finishSeekReadback(exitCode)
    }
    Timer {
        interval: 250
        repeat: true
        running: root.seekPending
        onTriggered: root.requestSeekReadback()
    }
    Timer { id: seekDispatch; interval: 90; onTriggered: root.dispatchQueued() }
    // Deliberately not multiples of the 250ms display refresh: a deadline can
    // never repeatedly race the refresh boundary. Failure is reported only
    // after one bounded late-confirmation window.
    Timer {
        id: seekConfirmationDeadline
        interval: 1375
        onTriggered: root.beginLateConfirmation(root.inFlightGeneration)
    }
    Timer {
        id: seekLateDeadline
        interval: 725
        onTriggered: root.finishConfirmation(root.inFlightGeneration)
    }
}
