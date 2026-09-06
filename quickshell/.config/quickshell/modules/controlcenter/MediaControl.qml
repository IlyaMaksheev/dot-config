import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root
    property bool effectiveVisible: Media.available
    property int preferredHeight: Appearance.controlCenterMediaHeight
    // Transport is the entry level; duration/progress is the level below it.
    property var moduleControls: [toggleButton, previousButton, nextButton, progress]
    readonly property var transportControls: [toggleButton, previousButton, nextButton]
    readonly property var progressControl: progress
    readonly property var entryControl: toggleButton.enabled ? toggleButton
        : previousButton.enabled ? previousButton : nextButton.enabled ? nextButton : progress
    readonly property var exitControl: progress.visible && progress.navigable ? progress : entryControl
    property var adoptPointer: function(control) {}
    property real titleOffset: 0

    function formatTime(seconds) {
        const bounded = Math.max(0, Math.floor(Number(seconds) || 0));
        const hours = Math.floor(bounded / 3600);
        const minutes = Math.floor((bounded % 3600) / 60);
        const remainder = bounded % 60;
        return hours > 0
            ? hours + ":" + String(minutes).padStart(2, "0") + ":" + String(remainder).padStart(2, "0")
            : minutes + ":" + String(remainder).padStart(2, "0");
    }

    function transportColor(control) {
        if (!control.enabled)
            return Appearance.surfaceRaised;
        if (control.pointerPressed)
            return Appearance.dark0;
        if (control.cursorActive || control.pointerHovered)
            return Appearance.dark3;
        return Appearance.surfaceRaised;
    }
    readonly property bool focusWithin: moduleControls.some(control => control && control.cursorActive)
    readonly property bool cardActive: cardHover.hovered || focusWithin
    readonly property real titleOverflow: Math.max(0, titleText.implicitWidth - titleViewport.width)
    readonly property bool titleMarqueeActive: !Appearance.reducedMotion && titleOverflow > 1 && cardActive

    function restartTitleMarquee() {
        titleMarquee.stop();
        titleOffset = 0;
        if (titleMarqueeActive)
            titleMarquee.start();
    }

    onTitleMarqueeActiveChanged: restartTitleMarquee()
    onTitleOverflowChanged: if (titleMarqueeActive) restartTitleMarquee()

    Connections {
        target: Media
        function onInteractionKeyChanged() {
            if (progress.adjustmentMode) {
                progress.adjustmentMode = false;
                Media.endSeekSession(false);
            }
        }
        function onRelativeSeekAvailableChanged() {
            if (!Media.relativeSeekAvailable)
                progress.adjustmentMode = false;
        }
    }

    HoverHandler { id: cardHover }

    Rectangle {
        anchors.fill: parent
        color: Appearance.surfaceBackground
        radius: Appearance.controlCenterRadius
        clip: true
        Behavior on color { ColorAnimation { duration: Appearance.feedbackAnimationDuration } }

        Rectangle {
            anchors.fill: artwork
            color: Appearance.panelBackground
            radius: Appearance.controlCenterRadius
            visible: Media.artwork.length > 0 && artwork.status !== Image.Ready
            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: Appearance.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontPixelSize * 2
            }
        }

        Image {
            id: artwork
            anchors.left: parent.left
            anchors.leftMargin: Appearance.controlCenterGap
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - Appearance.controlCenterGap * 2
            height: width
            source: Media.artwork
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: width
            sourceSize.height: height
            visible: status === Image.Ready
            clip: true
        }

        Item {
            id: metadata
            anchors.left: Media.artwork.length > 0 ? artwork.right : parent.left
            anchors.leftMargin: Appearance.controlCenterGap
            anchors.right: actions.left
            anchors.rightMargin: Appearance.controlCenterGap
            anchors.top: parent.top
            anchors.topMargin: Appearance.controlCenterGap
            anchors.bottom: progress.top
            anchors.bottomMargin: 4
            clip: true

            Item {
                id: titleViewport
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -titleText.implicitHeight / 2
                height: titleText.implicitHeight
                clip: true

                Text {
                    id: titleText
                    x: -root.titleOffset
                    text: Media.title
                    color: Appearance.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontPixelSize
                    font.bold: true
                    maximumLineCount: 1
                    elide: Appearance.reducedMotion ? Text.ElideRight : Text.ElideNone
                }

                SequentialAnimation {
                    id: titleMarquee
                    loops: Animation.Infinite
                    PauseAnimation { duration: 700 }
                    NumberAnimation {
                        target: root
                        property: "titleOffset"
                        from: 0
                        to: root.titleOverflow
                        duration: Math.min(5000, Math.max(1200, root.titleOverflow * 32))
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 650 }
                    PropertyAction { target: root; property: "titleOffset"; value: 0 }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: titleViewport.bottom
                text: Media.artist || (Media.available ? Media.selectedPlayer.identity : "")
                color: Appearance.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: Appearance.controlCenterGap
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -12
            spacing: 8

            IconButton {
                id: previousButton
                width: Appearance.controlCenterRowHeight
                height: width
                icon: "󰒮"
                visible: Media.available
                enabled: Media.canPrevious
                navigable: enabled
                opacity: enabled ? 1 : 0.45
                color: root.transportColor(previousButton)
                border.width: 1
                border.color: Appearance.dark3
                showFocusIndicator: false
                showCursorMarker: false
                strictVerticalNavigation: true
                navigationRight: toggleButton.enabled ? toggleButton : nextButton.enabled ? nextButton : null
                navigationDown: progress
                accessibleStatus: "Previous track"
                onActivated: Media.previous()
                onHovered: root.adoptPointer(previousButton)
            }
            IconButton {
                id: toggleButton
                width: Appearance.controlCenterRowHeight
                height: width
                icon: Media.playing ? "󰏤" : "󰐊"
                iconPixelSize: Appearance.fontPixelSize + 2
                visible: Media.available
                enabled: Media.canToggle
                navigable: enabled
                opacity: enabled ? 1 : 0.45
                color: root.transportColor(toggleButton)
                border.width: 1
                border.color: Media.playing ? Appearance.dark4 : Appearance.dark3
                showFocusIndicator: false
                showCursorMarker: false
                strictVerticalNavigation: true
                navigationLeft: previousButton.enabled ? previousButton : null
                navigationRight: nextButton.enabled ? nextButton : null
                navigationDown: progress.visible ? progress : null
                accessibleStatus: Media.playing ? "Pause media" : "Play media"
                onActivated: Media.togglePlaying()
                onHovered: root.adoptPointer(toggleButton)
            }
            IconButton {
                id: nextButton
                width: Appearance.controlCenterRowHeight
                height: width
                icon: "󰒭"
                visible: Media.available
                enabled: Media.canNext
                navigable: enabled
                opacity: enabled ? 1 : 0.45
                color: root.transportColor(nextButton)
                border.width: 1
                border.color: Appearance.dark3
                showFocusIndicator: false
                showCursorMarker: false
                strictVerticalNavigation: true
                navigationLeft: toggleButton.enabled ? toggleButton : previousButton.enabled ? previousButton : null
                navigationDown: progress
                accessibleStatus: "Next track"
                onActivated: Media.next()
                onHovered: root.adoptPointer(nextButton)
            }
        }

        InteractionSurface {
            id: progress
            anchors.left: Media.artwork.length > 0 ? artwork.right : parent.left
            anchors.leftMargin: Appearance.controlCenterGap
            anchors.right: actions.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Appearance.controlCenterGap
            height: 36
            visible: Media.available
            enabled: Media.relativeSeekAvailable && Media.progressReadable
            navigable: enabled
            opacity: enabled ? 1 : 0.5
            color: cursorActive || pointerHovered ? Appearance.surfaceHover : Appearance.surfaceBackground
            showFocusIndicator: false
            showCursorMarker: false
            strictVerticalNavigation: true
            navigationUp: root.entryControl

            property bool adjustmentMode: false
            readonly property real renderDuration: Media.progressDuration
            readonly property real displayPosition: Media.progressPosition
            readonly property real value: Media.progressReadable && renderDuration > 0
                ? Math.max(0, Math.min(1, displayPosition / renderDuration)) : 0
            readonly property bool seekActive: enabled && (adjustmentMode || seekMouse.pressed)
            accessibleStatus: Media.progressReadable
                ? "Media progress " + root.formatTime(displayPosition) + " of "
                    + (renderDuration > 0 ? root.formatTime(renderDuration) : "unknown duration")
                    + (Media.seekPending ? "; seek pending" : Media.seekFailed ? "; seek failed" : "")
                    + (adjustmentMode ? "; seek preview, h and l adjust, Enter or Space commits, Escape cancels" : "; Enter or Space to preview a seek")
                : "Media progress unavailable"

            function adjust(direction) {
                if (adjustmentMode)
                    Media.adjustSeek(direction);
            }
            function seekAt(pointerX) {
                if (!Media.absoluteSeekAvailable)
                    return;
                if (adjustmentMode)
                    adjustmentMode = false;
                const fraction = Math.max(0, Math.min(1,
                    (pointerX - rail.x) / Math.max(1, rail.width)));
                Media.seekFraction(fraction);
            }

            onActivated: {
                if (!adjustmentMode) {
                    if (Media.beginSeekSession(true))
                        adjustmentMode = true;
                } else {
                    // Activation is the only keyboard path that commits. Shared
                    // Escape, navigation, panel close, and pointer takeover all
                    // clear adjustmentMode and therefore cancel the draft.
                    Media.endSeekSession(true);
                    adjustmentMode = false;
                }
            }
            onAdjustmentModeChanged: {
                if (!adjustmentMode)
                    Media.endSeekSession(false);
            }
            onHovered: root.adoptPointer(progress)

            Text {
                anchors.left: parent.left
                anchors.right: parent.horizontalCenter
                anchors.top: parent.top
                text: Media.progressReadable ? root.formatTime(progress.displayPosition) : "--:--"
                color: progress.seekActive ? Appearance.bright_green : Appearance.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -8
                text: progress.adjustmentMode ? "[seek]" : Media.seekFailed ? "[failed]" : ""
                color: Media.seekFailed ? Appearance.bright_red : Appearance.textPrimary
                font.family: Appearance.fontFamily
                font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
            }
            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                text: progress.renderDuration > 0 ? root.formatTime(progress.renderDuration) : "--:--"
                color: progress.seekActive ? Appearance.bright_green : Appearance.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
            }

            Rectangle {
                id: rail
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 5
                radius: 1
                color: Appearance.dark3
            }
            Rectangle {
                anchors.left: rail.left
                anchors.verticalCenter: rail.verticalCenter
                height: rail.height
                width: rail.width * progress.value
                radius: 1
                color: progress.seekActive ? Appearance.bright_green : Appearance.light3
            }
            Rectangle {
                width: 12
                height: 12
                x: Math.max(rail.x, Math.min(rail.x + rail.width - width,
                    rail.x + rail.width * progress.value - width / 2))
                anchors.verticalCenter: rail.verticalCenter
                radius: 1
                visible: Media.progressReadable && (progress.adjustmentMode || seekMouse.pressed
                    || progress.cursorActive || (progress.pointerEngaged && seekMouse.containsMouse))
                color: progress.seekActive ? Appearance.bright_green : Appearance.light2
            }

            MouseArea {
                id: seekMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Media.absoluteSeekAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onContainsMouseChanged: if (!containsMouse) progress.pointerEngaged = false
                onPressed: mouse => {
                    if (!progress.pointerEngaged) {
                        progress.pointerEngaged = true;
                        progress.hovered();
                    }
                    progress.seekAt(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (!progress.pointerEngaged) {
                        progress.pointerEngaged = true;
                        progress.hovered();
                    }
                    if (pressed)
                        progress.seekAt(mouse.x);
                }
                onReleased: Media.endSeekSession(true)
                onCanceled: Media.endSeekSession(true)
                onWheel: wheel => {
                    if (Media.wheelSeek(wheel.angleDelta.y >= 0 ? 1 : -1))
                        wheel.accepted = true;
                    else
                        wheel.accepted = false;
                }
            }
        }
    }

    FocusIndicator { active: root.focusWithin }
}
