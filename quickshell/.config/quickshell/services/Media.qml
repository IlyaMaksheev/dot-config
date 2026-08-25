pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values || []
    property var selectedPlayer: null
    property real confirmedPosition: 0

    readonly property bool available: selectedPlayer !== null
    readonly property bool playing: available && selectedPlayer.playbackState === MprisPlaybackState.Playing
    readonly property bool paused: available && selectedPlayer.playbackState === MprisPlaybackState.Paused
    readonly property bool canPrevious: available && selectedPlayer.canControl && selectedPlayer.canGoPrevious
    readonly property bool canNext: available && selectedPlayer.canControl && selectedPlayer.canGoNext
    readonly property bool canToggle: available && selectedPlayer.canControl && selectedPlayer.canTogglePlaying
    readonly property bool canSeek: available && selectedPlayer.canControl && selectedPlayer.canSeek
        && selectedPlayer.positionSupported && selectedPlayer.lengthSupported && selectedPlayer.length > 0
    readonly property real length: available && selectedPlayer.lengthSupported ? Math.max(0, selectedPlayer.length) : 0
    readonly property string title: available && selectedPlayer.trackTitle ? selectedPlayer.trackTitle : (available ? selectedPlayer.identity : "")
    readonly property string artist: available ? selectedPlayer.trackArtist : ""
    readonly property string artwork: available ? selectedPlayer.trackArtUrl : ""

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
            if (rankDifference !== 0)
                return rankDifference;
            return String(left.dbusName).localeCompare(String(right.dbusName));
        });
        selectedPlayer = candidates.length ? candidates[0] : null;
        syncPosition();
    }

    function syncPosition() {
        confirmedPosition = available && selectedPlayer.positionSupported
            ? Math.max(0, selectedPlayer.position) : 0;
    }

    function invoke(capable, operation, failureKey, description) {
        if (!capable || !selectedPlayer)
            return;
        try {
            operation();
        } catch (error) {
            console.warn("MPRIS action failed:", error);
            OperationFailures.report(failureKey, "Media action failed", description);
            syncPosition();
        }
    }

    function previous() {
        invoke(canPrevious, () => selectedPlayer.previous(), "mpris-previous", "The player did not accept the previous-track request.");
    }

    function next() {
        invoke(canNext, () => selectedPlayer.next(), "mpris-next", "The player did not accept the next-track request.");
    }

    function togglePlaying() {
        invoke(canToggle, () => selectedPlayer.togglePlaying(), "mpris-toggle", "The player did not accept the play/pause request.");
    }

    function seek(fraction) {
        if (!canSeek)
            return;
        const target = Math.max(0, Math.min(1, fraction)) * length;
        invoke(true, () => { selectedPlayer.position = target; }, "mpris-seek", "The player did not accept the seek request.");
    }

    onPlayersChanged: reconcileSelection()
    Component.onCompleted: reconcileSelection()

    Connections {
        target: root.selectedPlayer
        ignoreUnknownSignals: true
        function onPlaybackStateChanged() { root.syncPosition(); }
        function onPositionChanged() { root.syncPosition(); }
        function onTrackChanged() { root.syncPosition(); }
        function onLengthChanged() { root.syncPosition(); }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.syncPosition()
    }
}
