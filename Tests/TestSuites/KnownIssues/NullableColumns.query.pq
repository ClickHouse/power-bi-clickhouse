// Nullable columns with real NULLs: load, aggregate, and filter correctly
// (guards the nullable-handling path; see COMPATIBILITY_SETTINGS_TODO for the cast caveat).
(source) =>
let
    nul = source[nullable],
    grouped = Table.Buffer(Table.Group(nul, {},
        {{"sumV", each List.Sum([v]), type number},
         {"sumN", each List.Sum([n]), Int64.Type},
         {"avgV", each List.Average([v]), type number},
         {"avgN", each List.Average([n]), type number},
         // the exact shape DAX emits for COUNTA / the count half of AVERAGE
         {"cntA", each List.Count(List.Select([v], each _ <> null)), Int64.Type},
         // the distinct half of DAX DISTINCTCOUNT (null handled by a separate indicator)
         {"dstA", each List.Count(List.Distinct(List.Select([v], each _ <> null))), Int64.Type},
         // NEGATIVE control: a compound predicate must NOT be folded as a plain COUNT —
         // the structural null-strip check rejects it, and the filtered count stays exact
         {"cntX", each List.Count(List.Select([n], each _ <> null and _ <> 10)), Int64.Type},
         // all-NULL effective set: M List.Average returns null (avgOrNull, not NaN-producing avg)
         {"avgAllNull", each List.Average(List.Select([v], each _ = null)), type nullable number},
         {"cnt", each Table.RowCount(_), Int64.Type}})){0},
    filtered = Table.Buffer(Table.SelectRows(nul, each [n] > 15))
in
    [SumV = grouped[sumV], SumN = grouped[sumN], AvgV = grouped[avgV], AvgN = grouped[avgN], CntA = grouped[cntA], DstA = grouped[dstA], CntX = grouped[cntX], AvgAllNull = grouped[avgAllNull], Rows = grouped[cnt], BigN = Table.RowCount(filtered)]
