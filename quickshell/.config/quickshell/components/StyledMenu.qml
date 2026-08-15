import Quickshell
import Quickshell.Widgets
import QtQuick
import "../theme"

PopupWindow {
    id: root

    required property var menuHandle
    required property Item anchorItem
    property bool submenu: false
    signal dismissed
    signal actionTriggered

    implicitWidth: Math.min(Math.max(220, menuColumn.implicitWidth + 2), Appearance.menuMaxWidth)
    implicitHeight: Math.min(menuColumn.implicitHeight + 2, 600)
    color: "transparent"
    grabFocus: !submenu

    anchor {
        item: root.anchorItem
        edges: root.submenu ? Edges.Right : Edges.Bottom
        gravity: root.submenu ? Edges.Right : Edges.Bottom
        adjustment: PopupAdjustment.All
    }

    function openMenu() {
        visible = true;
    }

    function closeMenu() {
        visible = false;
    }

    onVisibleChanged: {
        if (!visible) {
            closeDescendants();
            dismissed();
        }
    }

    function closeDescendants() {
        for (let i = 0; i < menuRepeater.count; ++i) {
            const row = menuRepeater.itemAt(i);
            if (row)
                row.closeSubmenu();
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.dark0
        focus: root.visible && !root.submenu

        Keys.onEscapePressed: root.closeMenu()
        border.color: Appearance.dark3
        border.width: 1

        Flickable {
            anchors {
                fill: parent
                margins: 1
            }
            contentWidth: width
            contentHeight: menuColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: menuColumn
                width: parent.width

                Repeater {
                    id: menuRepeater
                    model: opener.children

                    Item {
                        id: menuRow
                        required property var modelData
                        readonly property bool separator: modelData.isSeparator
                        readonly property bool hovered: mouseArea.containsMouse

                        width: menuColumn.width
                        height: separator ? 9 : Appearance.menuItemHeight

                        function openSubmenu() {
                            if (!modelData.hasChildren || !modelData.enabled)
                                return;

                            if (childMenu.item)
                                childMenu.item.openMenu();
                            else {
                                childMenu.active = true;
                                childMenu.setSource("StyledMenu.qml", {
                                    menuHandle: modelData,
                                    anchorItem: menuRow,
                                    submenu: true
                                });
                            }
                        }

                        function closeSubmenu() {
                            submenuTimer.stop();
                            if (childMenu.item)
                                childMenu.item.closeMenu();
                        }

                        Rectangle {
                            visible: menuRow.separator
                            height: 1
                            color: Appearance.dark3
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Appearance.menuHorizontalPadding
                                rightMargin: Appearance.menuHorizontalPadding
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: !menuRow.separator && menuRow.hovered && menuRow.modelData.enabled
                            color: Appearance.dark2
                        }

                        Rectangle {
                            visible: !menuRow.separator && menuRow.hovered && menuRow.modelData.enabled
                            height: 2
                            color: Appearance.bright_green
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                        }

                        StyledText {
                            id: checkmark
                            visible: !menuRow.separator && menuRow.modelData.buttonType !== QsMenuButtonType.None
                            text: menuRow.modelData.checkState === Qt.Checked ? (menuRow.modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓") : ""
                            color: Appearance.bright_green
                            width: 18
                            horizontalAlignment: Text.AlignHCenter
                            anchors {
                                left: parent.left
                                leftMargin: Appearance.menuHorizontalPadding
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        IconImage {
                            id: menuIcon
                            visible: !menuRow.separator && menuRow.modelData.icon !== ""
                            source: menuRow.modelData.icon
                            implicitWidth: 18
                            implicitHeight: 18
                            anchors {
                                left: parent.left
                                leftMargin: Appearance.menuHorizontalPadding
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            visible: !menuRow.separator
                            text: menuRow.modelData.text
                            color: menuRow.modelData.enabled ? Appearance.light1 : Appearance.dark4
                            elide: Text.ElideRight
                            anchors {
                                left: parent.left
                                right: submenuArrow.left
                                leftMargin: Appearance.menuHorizontalPadding + ((menuRow.modelData.icon !== "" || menuRow.modelData.buttonType !== QsMenuButtonType.None) ? 26 : 0)
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            id: submenuArrow
                            visible: !menuRow.separator && menuRow.modelData.hasChildren
                            text: "›"
                            color: menuRow.modelData.enabled ? Appearance.light4 : Appearance.dark4
                            anchors {
                                right: parent.right
                                rightMargin: Appearance.menuHorizontalPadding
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Timer {
                            id: submenuTimer
                            interval: 250
                            onTriggered: menuRow.openSubmenu()
                        }

                        Loader {
                            id: childMenu
                            active: false

                            onLoaded: item.openMenu()
                        }

                        Connections {
                            target: childMenu.item

                            function onActionTriggered() {
                                root.actionTriggered();
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            enabled: !menuRow.separator
                            hoverEnabled: true

                            onEntered: {
                                root.closeDescendants();
                                if (menuRow.modelData.hasChildren && menuRow.modelData.enabled)
                                    submenuTimer.start();
                            }

                            onClicked: {
                                if (!menuRow.modelData.enabled)
                                    return;

                                if (menuRow.modelData.hasChildren) {
                                    menuRow.openSubmenu();
                                } else {
                                    menuRow.modelData.triggered();
                                    root.actionTriggered();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
