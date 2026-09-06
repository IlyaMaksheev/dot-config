pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property date currentDate: clock.date
    readonly property string time: Qt.formatDateTime(currentDate, "yyyy-MM-dd HH:mm:ss")

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
