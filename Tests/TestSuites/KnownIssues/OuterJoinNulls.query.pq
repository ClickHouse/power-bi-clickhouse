// Outer merges must preserve M null semantics: unmatched rows carry null, not ClickHouse's
// join_use_nulls = 0 type defaults (0, ''). Outer-join folding is disabled in the generator
// because the connector cannot force join_use_nulls = 1 on the server; this test fails
// (NullA = 0) if outer joins ever fold again without null preservation.
// text has rid 1-5, division has rid 1-3, so a left outer join leaves 2 unmatched rows.
(source) =>
let
    t = Table.SelectColumns(source[text], {"rid", "s"}),
    d = Table.RenameColumns(source[division], {{"rid", "drid"}, {"a", "da"}, {"b", "db"}}),
    j = Table.Buffer(Table.Join(t, "rid", d, "drid", JoinKind.LeftOuter)),
    nullA = Table.RowCount(Table.SelectRows(j, each [da] = null))
in
    [Rows = Table.RowCount(j), NullA = nullA]
