const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const model = vm.createContext({});
vm.runInContext(fs.readFileSync(`${__dirname}/modules/calendar/CalendarModel.js`, 'utf8'), model);
assert.equal(model.daysInMonth(2000, 2), 29);
assert.equal(model.daysInMonth(1900, 2), 28);
assert.equal(model.daysInMonth(2024, 2), 29);
assert.equal(model.daysInMonth(2023, 2), 28);
[31,28,31,30,31,30,31,31,30,31,30,31].forEach((n, i) => assert.equal(model.daysInMonth(2023, i + 1), n));
assert.equal(model.stepMonth(2024, 12, 1).key, '2025-01-01');
assert.equal(model.stepMonth(2025, 1, -1).key, '2024-12-01');
for (let year = 1999; year <= 2030; year++) {
    for (let month = 1; month <= 12; month++) {
        const rows = model.monthGrid(year, month);
        assert.equal(rows.length, 6);
        assert(rows.every(row => row.days.length === 7));
        const cells = rows.flatMap(row => row.days);
        assert.equal(new Set(cells.map(cell => cell.key)).size, 42);
        assert.equal(cells.filter(cell => cell.inMonth).length, model.daysInMonth(year, month));
        rows.forEach(row => assert.equal(model.date(row.days[0].year, row.days[0].month, row.days[0].day).getUTCDay(), 1));
        cells.forEach((cell, i) => {
            if (i) assert.equal(model.date(cell.year, cell.month, cell.day) - model.date(cells[i-1].year, cells[i-1].month, cells[i-1].day), 86400000);
        });
    }
}
const january = model.monthGrid(2021, 1);
assert.equal(january[0].days[0].key, '2020-12-28');
assert.equal(january[5].days[6].key, '2021-02-07');
assert.equal(january[0].days[0].inMonth, false);
for (const [y,m,d,wy,w] of [[2021,1,1,2020,53],[2021,1,4,2021,1],[2018,12,31,2019,1],[2016,1,3,2015,53],[2020,12,31,2020,53]]) {
    assert.equal(model.isoWeek(y,m,d).year, wy);
    assert.equal(model.isoWeek(y,m,d).week, w);
}
console.log('Calendar model: all assertions passed (384 month grids)');
