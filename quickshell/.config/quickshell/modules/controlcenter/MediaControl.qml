import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root
    property bool effectiveVisible: Media.available
    property int preferredHeight: Appearance.controlCenterMediaHeight
    property var moduleControls: [progress, previousButton, toggleButton, nextButton]
    property var adoptPointer: function(control) {}

    Rectangle {
        anchors.fill: parent
        color: Appearance.surfaceBackground
        radius: Appearance.controlCenterRadius

        Image {
            id: artwork
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: height
            source: Media.artwork
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: source.toString().length > 0
            clip: true
        }

        Item {
            id: details
            anchors.left: artwork.visible ? artwork.right : parent.left
            anchors.leftMargin: artwork.visible ? Appearance.controlCenterGap : Appearance.controlCenterPadding
            anchors.right: parent.right
            anchors.rightMargin: Appearance.controlCenterPadding
            anchors.top: parent.top
            anchors.topMargin: Appearance.controlCenterGap
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Appearance.controlCenterGap

            Text {
                id: title
                anchors.left: parent.left
                anchors.right: parent.right
                text: Media.title
                color: Appearance.textPrimary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontPixelSize
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                id: artist
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: title.bottom
                text: Media.artist || (Media.available ? Media.selectedPlayer.identity : "")
                color: Appearance.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Row {
                id: actions
                anchors.left: parent.left
                anchors.bottom: progress.top
                anchors.bottomMargin: 4
                spacing: Appearance.controlCenterGap

                IconButton {
                    id: previousButton
                    icon: "󰒮"
                    visible: Media.canPrevious
                    navigable: visible
                    accessibleStatus: "Previous track"
                    onActivated: Media.previous()
                    onHovered: root.adoptPointer(previousButton)
                }
                IconButton {
                    id: toggleButton
                    icon: Media.playing ? "󰏤" : "󰐊"
                    visible: Media.canToggle
                    navigable: visible
                    accessibleStatus: Media.playing ? "Pause media" : "Play media"
                    onActivated: Media.togglePlaying()
                    onHovered: root.adoptPointer(toggleButton)
                }
                IconButton {
                    id: nextButton
                    icon: "󰒭"
                    visible: Media.canNext
                    navigable: visible
                    accessibleStatus: "Next track"
                    onActivated: Media.next()
                    onHovered: root.adoptPointer(nextButton)
                }
            }

            SquareSlider {
                id: progress
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 18
                value: Media.length > 0 ? Math.min(1, Media.confirmedPosition / Media.length) : 0
                enabled: Media.canSeek
                visible: Media.length > 0
                navigable: enabled
                stepSize: Media.length > 0 ? Math.min(1, 5 / Media.length) : 0.01
                accessibleStatus: "Media progress " + Math.round(value * 100) + " percent"
                onValueRequested: value => Media.seek(value)
                onHovered: root.adoptPointer(progress)
            }
        }
    }
}
