// Full date-override coverage on the 2024-02-29 leap row: part extraction (toYear/toMonth/
// toDayOfMonth), period starts (toStartOfYear/Quarter/Month), the date-input passthrough
// branch of StartOfDay, and the whole add* family (leap clamping). toStartOfDay over a
// DateTime column is NOT tested: plain DateTime travels as Arrow uint32 (see KnownIssues/PlainDateTime).
(source) =>
let
    fd = (x) => Date.ToText(x, [Format = "yyyy-MM-dd"]),
    t = Table.Buffer(Table.SelectRows(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(source[dates],
            "y",   each Date.Year([d]), Int64.Type),
            "m",   each Date.Month([d]), Int64.Type),
            "day", each Date.Day([d]), Int64.Type),
            "soy", each Date.StartOfYear([d]), type date),
            "soq", each Date.StartOfQuarter([d]), type date),
            "som", each Date.StartOfMonth([d]), type date),
            "sodD",  each Date.StartOfDay([d]), type date),
            "ay",  each Date.AddYears([d], 1), type date),
            "ad",  each Date.AddDays([d], 1), type date),
            "am",  each Date.AddMonths([d], 12), type date),
            "aq",  each Date.AddQuarters([d], 1), type date),
            "aw",  each Date.AddWeeks([d], 1), type date),
        each [rid] = 2)){0}
in
    [
        Y = t[y], M = t[m], D = t[day],
        SOY = fd(t[soy]), SOQ = fd(t[soq]), SOM = fd(t[som]),
        SODd = fd(t[sodD]),
        AddD = fd(t[ad]), AddM = fd(t[am]), AddQ = fd(t[aq]), AddW = fd(t[aw]), AddY = fd(t[ay])
    ]
