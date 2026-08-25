import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root
    property bool effectiveVisible: true
    property int preferredHeight: Appearance.controlCenterSliderHeight
    property var moduleControls: [slider, muteButton]
    property var adoptPointer: function(control) {}

    SquareSlider {
        id: slider
        anchors.left: parent.left
        anchors.right: muteButton.left
        anchors.rightMargin: Appearance.controlCenterControlGap
        height: parent.height
        value: Audio.available ? Audio.volume : 0
        enabled: Audio.available
        navigable: true
        accessibleStatus: Audio.available ? "Output volume " + Math.round(Audio.volume * 100) + " percent" : "Volume unavailable"
        label: Audio.available ? "󰕾  " + Math.round(Audio.volume * 100) + "%" : "󰕾  Volume unavailable"
        onValueRequested: value => Audio.requestVolume(value)
        onHovered: root.adoptPointer(slider)
    }

    IconButton {
        id: muteButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        icon: !Audio.available ? "󰖁" : Audio.muted ? "󰖁" : "󰕾"
        enabled: Audio.available
        selected: Audio.available && Audio.muted
        navigable: true
        accessibleStatus: !Audio.available ? "Mute unavailable" : Audio.muted ? "Output muted" : "Output unmuted"
        onActivated: Audio.requestMuteToggle()
        onHovered: root.adoptPointer(muteButton)
    }
}
