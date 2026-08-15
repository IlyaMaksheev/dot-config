import Quickshell
import QtQuick
import "../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    required property string text
    property bool requested: false

    implicitWidth: Math.min(label.implicitWidth + 12, Appearance.menuMaxWidth)
    implicitHeight: label.implicitHeight + 8
    color: "transparent"

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.All
        margins.top: 4
    }

    onRequestedChanged: {
        if (requested && text !== "")
            showTimer.restart();
        else {
            showTimer.stop();
            visible = false;
        }
    }

    Timer {
        id: showTimer
        interval: 500
        onTriggered: root.visible = root.requested && root.text !== ""
    }

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: Appearance.dark1
        border.color: Appearance.dark3
        border.width: 1

        StyledText {
            id: label
            text: root.text
            color: Appearance.light1
            elide: Text.ElideRight
            anchors.centerIn: parent
            width: Math.min(implicitWidth, Appearance.menuMaxWidth - 12)
        }
    }
}
