pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls as Controls
import "../../services"
import "../../theme"
import "CalendarModel.js" as Model

Singleton {
    id: root
    property bool isOpen: false
    property string targetOutput: ""
    property string mode: "month"
    property int year: Time.currentDate.getFullYear()
    property int month: Time.currentDate.getMonth() + 1
    readonly property string todayKey: Qt.formatDateTime(Time.currentDate, "yyyy-MM-dd")

    function screenForOutput(name) {
        for (const screen of Quickshell.screens) {
            if (screen.name === name) return screen;
        }
        return null;
    }
    function today() {
        year = Time.currentDate.getFullYear();
        month = Time.currentDate.getMonth() + 1;
    }
    function step(delta) {
        const next = Model.stepPeriod(year, month, mode, delta);
        year = next.year;
        month = next.month;
    }
    function open(output) {
        if (!screenForOutput(output)) { close(); return; }
        PopupCoordinator.activate(root);
        today();
        targetOutput = output;
        isOpen = true;
    }
    function close() {
        isOpen = false;
        targetOutput = "";
        PopupCoordinator.release(root);
    }
    function toggle(output) { if (isOpen) close(); else open(output); }
    Component.onDestruction: PopupCoordinator.release(root)
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.isOpen && !root.screenForOutput(root.targetOutput)) root.close();
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: overlay
            required property var modelData
            readonly property bool ownsPanel: root.isOpen && root.targetOutput === modelData.name
            screen: modelData
            visible: root.isOpen
            color: "transparent"
            exclusiveZone: 0
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ownsPanel ? WlrKeyboardFocus.Exclusive : root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            onOwnsPanelChanged: if (ownsPanel) Qt.callLater(() => panel.forceActiveFocus(Qt.PopupFocusReason))
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.close()
                onWheel: wheel => wheel.accepted = true
            }
            Rectangle {
                id: panel
                visible: overlay.ownsPanel
                focus: overlay.ownsPanel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.min(overlay.height, Appearance.barHeight + Appearance.calendarEdgeGap)
                width: Math.max(0, Math.min(root.mode === "year" ? Appearance.calendarYearWidth : Appearance.calendarMonthWidth, overlay.width - Appearance.calendarEdgeGap * 2))
                height: Math.max(0, Math.min(header.height + content.implicitHeight + Appearance.calendarPadding * 2, overlay.height - y - Appearance.calendarEdgeGap))
                color: Appearance.dark0
                border.color: activeFocus ? Appearance.focusColor : Appearance.panelBorder
                border.width: Appearance.calendarBorderWidth
                clip: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.close();
                    else if (event.key === Qt.Key_Left) root.step(-1);
                    else if (event.key === Qt.Key_Right) root.step(1);
                    else if (event.key === Qt.Key_T) root.today();
                    else if (event.key === Qt.Key_M) root.mode = "month";
                    else if (event.key === Qt.Key_Y) root.mode = "year";
                    else return;
                    event.accepted = true;
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: mouse => mouse.accepted = true
                    onWheel: wheel => {
                        const delta = wheel.angleDelta.y || wheel.angleDelta.x;
                        if (delta !== 0) root.step(delta > 0 ? -1 : 1);
                        wheel.accepted = true;
                    }
                }
                // Navigation stays outside the panning surface: it must remain
                // clickable and visible even when a constrained year view scrolls.
                Row {
                    id: header
                    x: Appearance.calendarPadding
                    y: Appearance.calendarPadding
                    CalendarButton { text: '‹'; onClicked: root.step(-1) }
                    CalendarButton { text: 'Today'; onClicked: root.today() }
                    CalendarButton { text: 'Month'; border.width: root.mode === 'month' ? 1 : 0; border.color: Appearance.panelBorder; onClicked: root.mode = 'month' }
                    CalendarButton { text: 'Year'; border.width: root.mode === 'year' ? 1 : 0; border.color: Appearance.panelBorder; onClicked: root.mode = 'year' }
                    CalendarButton { text: '›'; onClicked: root.step(1) }
                }
                Flickable {
                    id: viewport
                    anchors.fill: parent
                    anchors.margins: Appearance.calendarPadding
                    anchors.topMargin: Appearance.calendarPadding + header.height
                    clip: true
                    contentWidth: content.width
                    contentHeight: content.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    Controls.ScrollBar.vertical: Controls.ScrollBar { }
                    Controls.ScrollBar.horizontal: Controls.ScrollBar { }
                    // Wheel browses periods; drag the scrollbars (or flick) to pan a constrained layout.
                    WheelHandler {
                        target: null
                        onWheel: event => {
                            const delta = event.angleDelta.y || event.angleDelta.x;
                            if (delta !== 0) root.step(delta > 0 ? -1 : 1);
                            event.accepted = true;
                        }
                    }
                    Connections {
                        target: root
                        function onModeChanged() { viewport.contentX = 0; viewport.contentY = 0; }
                        function onIsOpenChanged() { viewport.contentX = 0; viewport.contentY = 0; }
                    }
                    Column {
                    id: content
                    width: (root.mode === "year" ? Appearance.calendarYearWidth : Appearance.calendarMonthWidth) - Appearance.calendarPadding * 2
                    Text {
                        width: parent.width
                        height: Appearance.calendarCellHeight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: root.mode === 'year' ? root.year : Qt.locale().standaloneMonthName(root.month - 1, Locale.LongFormat) + ' ' + root.year
                        color: Appearance.light_green
                        font.family: Appearance.calendarFontFamily
                        font.pixelSize: Appearance.calendarFontSize
                    }
                    MonthGrid { visible: root.mode === 'month'; width: parent.width; year: root.year; month: root.month; todayKey: root.todayKey }
                    YearGrid {
                        visible: root.mode === 'year'
                        year: root.year
                        todayKey: root.todayKey
                        onMonthOpened: (year, month) => {
                            root.year = year;
                            root.month = month;
                            root.mode = 'month';
                        }
                    }
                    }
                }
            }
        }
    }
}
