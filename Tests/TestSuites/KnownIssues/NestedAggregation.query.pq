// Aggregating an already-aggregated column (the shape report visuals generate).
// Regression guard for: alias collisions (ILLEGAL_AGGREGATION on ClickHouse).
(source) =>
let
    inner = Table.Group(source[events], {"name"}, {{"subtotal", each List.Sum([val]), type number}}),
    TotalOfTotals = List.Sum(Table.Buffer(inner)[subtotal])
in
    [
        Total = Number.Round(TotalOfTotals, 2)  // expect sum of 0..99 / 8 = 618.75
    ]
