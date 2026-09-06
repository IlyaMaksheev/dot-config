pragma ComponentBehavior: Bound
import QtQuick
import "../../theme"
import "CalendarModel.js" as Model

Grid {
    id: root
    required property int year
    required property string todayKey
    signal monthOpened(int year, int month)
    columns: 3
    spacing: Appearance.calendarYearGap
    Repeater {
        model: Model.yearMonths(root.year)
        Column {
            id: miniMonth
            required property var modelData
            width: Appearance.calendarMiniMonthWidth
            CalendarButton {
                width: parent.width
                text: Qt.locale().standaloneMonthName(miniMonth.modelData.month - 1, Locale.LongFormat)
                onClicked: root.monthOpened(miniMonth.modelData.year, miniMonth.modelData.month)
            }
            MonthGrid {
                width: parent.width
                year: miniMonth.modelData.year
                month: miniMonth.modelData.month
                todayKey: root.todayKey
            }
        }
    }
}
