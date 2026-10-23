// AVG over integer and decimal columns folds and returns fractional results
// (the result type is Float64, not the input type).
(source) =>
let
    intAvg = Table.Group(source[events], {}, {{"a", each List.Average([id]), type number}}),
    decAvg = Table.Group(source[numbers], {}, {{"a", each List.Average([dec92]), type number}})
in
    [
        AvgEventsId = Table.Buffer(intAvg){0}[a],
        AvgDecimal = Number.Round(Table.Buffer(decAvg){0}[a], 2)
    ]
