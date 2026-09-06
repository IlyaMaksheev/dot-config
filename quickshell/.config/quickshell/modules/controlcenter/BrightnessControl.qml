import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root
    property bool panelVisible: false
    property bool effectiveVisible: Backlight.available
    property int preferredHeight: Appearance.controlCenterSliderHeight
    property var moduleControls: effectiveVisible ? [slider] : []
    readonly property var entryControl: slider
    property var adoptPointer: function(control) {}

    onPanelVisibleChanged: Backlight.setPanelVisible(panelVisible)
    Component.onCompleted: Backlight.setPanelVisible(panelVisible)

    SquareSlider {
        id: slider
        anchors.fill: parent
        value: Backlight.value
        stepSize: 0.01
        enabled: Backlight.available && Backlight.writable
        navigable: Backlight.available
        accessibleStatus: !Backlight.available ? "Internal brightness unavailable"
            : "Internal brightness " + Math.round(Backlight.value * 100) + " percent on " + Backlight.selectedDevice
                + (Backlight.writable ? "" : ", read only")
        label: "󰃠  " + Math.round(Backlight.value * 100) + "%" + (Backlight.writable ? "" : "  Read only")
        onValueRequested: value => Backlight.requestValue(value)
        onHovered: root.adoptPointer(slider)
    }
}
