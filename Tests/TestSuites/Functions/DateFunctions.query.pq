// Date function coverage: Year/Month/Day/AddDays/StartOfMonth (DirectQuery function list).
(source) =>
let
    withParts = Table.AddColumn(
        Table.AddColumn(
            Table.AddColumn(source[dates], "y", each Date.Year([d]), Int64.Type),
            "m", each Date.Month([d]), Int64.Type),
        "plus7", each Date.AddDays([d], 7), type date),
    buffered = Table.Buffer(Table.Sort(withParts, {{"rid", Order.Ascending}}))
in
    [
        Y1 = buffered{0}[y],
        M2 = buffered{1}[m],
        LeapPlus7 = Date.ToText(buffered{1}[plus7], [Format = "yyyy-MM-dd"]),
        StartOfMonth3 = Date.ToText(Date.StartOfMonth(buffered{2}[d]), [Format = "yyyy-MM-dd"])
    ]
