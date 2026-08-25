import QtQuick
import "../theme"

InteractionSurface {
    id: root
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    implicitHeight: Appearance.controlCenterTileHeight

    Column {
        anchors.fill: parent
        anchors.margins: Appearance.controlCenterGap
        spacing: 2
        Text { text: root.icon + (root.icon ? "  " : "") + root.title; color: Appearance.textPrimary; font.family: Appearance.fontFamily; font.pixelSize: Appearance.fontPixelSize; font.bold: true }
        Text { text: root.subtitle; color: root.enabled ? Appearance.textSecondary : Appearance.disabledColor; font.family: Appearance.fontFamily; font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3); elide: Text.ElideRight; width: parent.width }
    }
}
