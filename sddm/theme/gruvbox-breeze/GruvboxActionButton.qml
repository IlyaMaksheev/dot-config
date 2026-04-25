/* Gruvbox-local copy of KDE Breeze ActionButton for SDDM */

import QtQuick
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.AbstractButton {
    id: root
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    property bool actionEnabled: true
    signal activated()

    onClicked: {
        if (actionEnabled) {
            activated();
        }
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    Kirigami.Theme.backgroundColor: "#32302f"
    Kirigami.Theme.textColor: actionEnabled ? "#ebdbb2" : "#665c54"
    Kirigami.Theme.highlightColor: "#a89984"
    Kirigami.Theme.highlightedTextColor: "#1d2021"

    palette.window: "#32302f"
    palette.button: "#32302f"
    palette.text: actionEnabled ? "#ebdbb2" : "#665c54"
    palette.buttonText: actionEnabled ? "#ebdbb2" : "#665c54"
    palette.highlight: "#a89984"
    palette.highlightedText: "#1d2021"

    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
    font.underline: root.activeFocus

    icon.width: Kirigami.Units.iconSizes.large
    icon.height: Kirigami.Units.iconSizes.large
    
    hoverEnabled: true

    leftInset: Math.max(Kirigami.Units.largeSpacing * 4, (implicitContentWidth - implicitBackgroundWidth) / 2)
    rightInset: leftInset

    padding: Kirigami.Units.smallSpacing
    horizontalPadding: 0
    bottomPadding: 0
    spacing: padding + Kirigami.Units.smallSpacing

    opacity: root.activeFocus || root.hovered ? 1 : 0.9
    Behavior on opacity {
        PropertyAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    Kirigami.MnemonicData.enabled: root.actionEnabled && root.visible
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.SecondaryControl
    Kirigami.MnemonicData.label: root.text

    Shortcut {
        enabled: root.actionEnabled && !(RegExp(/\&[^\&]/).test(root.text))
        sequence: root.Kirigami.MnemonicData.sequence
        onActivated: root.animateClick()
    }

    background: Rectangle {
        implicitWidth: root.icon.width + root.padding * 2
        implicitHeight: root.icon.height + root.padding * 2
        width: implicitWidth
        height: implicitHeight
        radius: 6
        color: root.actionEnabled
            ? (root.down ? "#504945" : (root.activeFocus || root.hovered ? "#3c3836" : "#32302f"))
            : (root.activeFocus || root.hovered ? "#32302f" : "#282828")
        border.color: root.actionEnabled
            ? (root.activeFocus || root.hovered ? "#504945" : "transparent")
            : (root.activeFocus || root.hovered ? "#504945" : "transparent")
        border.width: root.activeFocus || root.hovered ? 1 : 0
        opacity: root.actionEnabled
            ? (root.activeFocus || root.hovered || root.down ? 0.95 : 0)
            : (root.activeFocus || root.hovered ? 0.55 : 0)
        Behavior on opacity {
            PropertyAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#504945"
            opacity: root.actionEnabled && root.down ? 0.35 : 0
            Behavior on opacity {
                PropertyAnimation {
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.InOutQuart
                }
            }
        }
    }

    contentItem: Column {
        spacing: root.spacing
        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: true
            source: root.icon.name
            implicitWidth: root.icon.width
            implicitHeight: root.icon.height
            color: root.actionEnabled
                ? (root.activeFocus || root.hovered ? "#ebdbb2" : "#a89984")
                : (root.activeFocus || root.hovered ? "#a89984" : "#665c54")
            active: false
        }
        PlasmaComponents3.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: true
            width: Math.min(implicitWidth, parent.width)
            text: root.Kirigami.MnemonicData.richTextLabel
            color: root.actionEnabled
                ? (root.activeFocus || root.hovered ? "#ebdbb2" : "#a89984")
                : (root.activeFocus || root.hovered ? "#a89984" : "#665c54")
            style: root.softwareRendering ? Text.Outline : Text.Normal
            styleColor: "#1d2021"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            textFormat: Text.StyledText
            wrapMode: Text.WordWrap
        }
    }

    Keys.onEnterPressed: if (root.actionEnabled) clicked()
    Keys.onReturnPressed: if (root.actionEnabled) clicked()
}
