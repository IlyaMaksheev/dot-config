import QtQuick
import "../theme"

InteractionSurface {
    id: root
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    implicitHeight: Appearance.controlCenterTileHeight
    property real marqueeOffset: 0
    readonly property real marqueeOverflow: Math.max(0, subtitleText.implicitWidth - subtitleViewport.width)
    readonly property bool marqueeActive: !Appearance.reducedMotion && marqueeOverflow > 1
        && (root.cursorActive || root.pointerHovered)

    onMarqueeActiveChanged: {
        marquee.stop();
        marqueeOffset = 0;
        if (marqueeActive)
            marquee.start();
    }

    Column {
        anchors.fill: parent
        anchors.margins: Appearance.controlCenterGap
        spacing: 2
        Text { text: root.icon + (root.icon ? "  " : "") + root.title; color: Appearance.textPrimary; font.family: Appearance.fontFamily; font.pixelSize: Appearance.fontPixelSize; font.bold: true }
        Item {
            id: subtitleViewport
            width: parent.width
            height: subtitleText.implicitHeight
            clip: true

            Text {
                id: subtitleText
                x: -root.marqueeOffset
                text: root.subtitle
                color: root.enabled ? Appearance.textSecondary : Appearance.disabledColor
                font.family: Appearance.fontFamily
                font.pixelSize: Math.max(11, Appearance.fontPixelSize - 3)
                maximumLineCount: 1
                elide: Appearance.reducedMotion ? Text.ElideRight : Text.ElideNone
            }

            SequentialAnimation {
                id: marquee
                loops: Animation.Infinite
                alwaysRunToEnd: false
                PauseAnimation { duration: 700 }
                NumberAnimation {
                    target: root
                    property: "marqueeOffset"
                    from: 0
                    to: root.marqueeOverflow
                    duration: Math.min(4500, Math.max(1000, root.marqueeOverflow * 32))
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 650 }
                PropertyAction { target: root; property: "marqueeOffset"; value: 0 }
            }
        }
    }
}
