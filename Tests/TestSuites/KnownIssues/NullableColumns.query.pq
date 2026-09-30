// Nullable columns with real NULLs: load, aggregate, and filter correctly
// (guards the nullable-handling path; see COMPATIBILITY_SETTINGS_TODO for the cast caveat).
(source) =>
let
    nul = source[nullable],
    grouped = Table.Buffer(Table.Group(nul, {},
        {{"sumV", each List.Sum([v]), type number},
         {"sumN", each List.Sum([n]), Int64.Type},
         {"cnt", each Table.RowCount(_), Int64.Type}})){0},
    filtered = Table.Buffer(Table.SelectRows(nul, each [n] > 15))
in
    [SumV = grouped[sumV], SumN = grouped[sumN], Rows = grouped[cnt], BigN = Table.RowCount(filtered)]
