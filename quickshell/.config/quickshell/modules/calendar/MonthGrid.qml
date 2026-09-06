pragma ComponentBehavior: Bound
import QtQuick
import "../../theme"
import "CalendarModel.js" as Model

Column {
    id: root
    required property int year
    required property int month
    required property string todayKey
    readonly property var weeks: Model.monthGrid(year, month)
    readonly property real cellWidth: width / 8

    Row {
        Repeater {
            model: 8
            Text {
                required property int index
                width: root.cellWidth
                height: Appearance.calendarCellHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: Appearance.calendarFontFamily
                font.pixelSize: Appearance.calendarFontSize
                color: Appearance.textPrimary
                text: index < 7 ? Qt.locale().standaloneDayName(index + 1, Locale.ShortFormat) : '#'
            }
        }
    }
    Repeater {
        model: root.weeks
        Row {
            id: weekRow
            required property var modelData
            Repeater {
                model: weekRow.modelData.days
                Text {
                    required property var modelData
                    // Full civil identity is retained for future event attachment. No selection handler.
                    readonly property var dateData: modelData
                    readonly property bool isToday: dateData.key === root.todayKey
                    width: root.cellWidth
                    height: Appearance.calendarCellHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: dateData.day
                    font.family: Appearance.calendarFontFamily
                    font.pixelSize: Appearance.calendarFontSize
                    font.bold: isToday
                    font.underline: isToday
                    color: isToday ? Appearance.bright_green : dateData.inMonth ? Appearance.textSecondary : Appearance.dark4
                }
            }
            Text {
                width: root.cellWidth
                height: Appearance.calendarCellHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: weekRow.modelData.iso.week
                font.family: Appearance.calendarFontFamily
                font.pixelSize: Appearance.calendarFontSize
                color: Appearance.bright_aqua
            }
        }
    }
}
