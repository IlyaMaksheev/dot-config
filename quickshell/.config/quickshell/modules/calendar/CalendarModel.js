// UTC arithmetic avoids DST gaps; returned civil dates have one-based months.
function date(year, month, day) {
    var value = new Date(0);
    value.setUTCFullYear(year, month - 1, day);
    value.setUTCHours(0, 0, 0, 0);
    return value;
}
function identity(year, month, day) {
    return String(year).padStart(4, '0') + '-' + String(month).padStart(2, '0') + '-' + String(day).padStart(2, '0');
}
function civil(value) {
    var year = value.getUTCFullYear(), month = value.getUTCMonth() + 1, day = value.getUTCDate();
    return { year: year, month: month, day: day, key: identity(year, month, day) };
}
function daysInMonth(year, month) { return date(year, month + 1, 0).getUTCDate(); }
function stepMonth(year, month, delta) { return civil(date(year, month + delta, 1)); }
function isoWeek(year, month, day) {
    var thursday = date(year, month, day);
    thursday.setUTCDate(thursday.getUTCDate() + 3 - (thursday.getUTCDay() + 6) % 7);
    var weekYear = thursday.getUTCFullYear();
    return { year: weekYear, week: Math.floor((thursday - date(weekYear, 1, 1)) / 86400000 / 7) + 1 };
}
function monthGrid(year, month) {
    var first = date(year, month, 1);
    var offset = (first.getUTCDay() + 6) % 7;
    var rows = [];
    for (var row = 0; row < 6; row++) {
        var days = [];
        for (var column = 0; column < 7; column++) {
            var cell = civil(date(year, month, 1 - offset + row * 7 + column));
            cell.inMonth = cell.year === year && cell.month === month;
            days.push(cell);
        }
        rows.push({ days: days, iso: isoWeek(days[0].year, days[0].month, days[0].day) });
    }
    return rows;
}
