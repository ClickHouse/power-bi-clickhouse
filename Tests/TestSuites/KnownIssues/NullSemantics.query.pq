// M null semantics preserved in folded SQL (n = {10, null, 20, 30}, v has 2 nulls):
// List.Count counts nulls; List.Distinct keeps null as a value; List.Contains with a null
// member matches null rows; an empty membership list is false. The approximate distinct
// count keeps native uniq semantics (null-skipping) and the engine refuses it over nullable
// columns entirely, so it is not exercised here (see Folding/ApproxDistinct).
(source) =>
let
    nul = source[nullable],
    g = Table.Buffer(Table.Group(nul, {}, {
        {"cnt", each List.Count([n]), Int64.Type},
        {"dst", each List.Count(List.Distinct([n])), Int64.Type},
        {"tdst", each Table.RowCount(Table.Distinct(Table.SelectColumns(_, {"n"}))), Int64.Type},
        {"mdst", each Table.RowCount(Table.Distinct(Table.SelectColumns(_, {"v", "n"}))), Int64.Type}})){0},
    memberWithNull = Table.RowCount(Table.Buffer(Table.SelectRows(nul, each List.Contains({null, 10}, [n])))),
    memberOnlyNull = Table.RowCount(Table.Buffer(Table.SelectRows(nul, each List.Contains({null}, [n])))),
    memberPlain = Table.RowCount(Table.Buffer(Table.SelectRows(nul, each List.Contains({10, 20}, [n])))),
    memberEmpty = Table.RowCount(Table.Buffer(Table.SelectRows(nul, each List.Contains({}, [n]))))
in
    [
        CountWithNulls = g[cnt], DistinctWithNull = g[dst], TableDistinct = g[tdst],
        MultiColDistinct = g[mdst],
        MemberWithNull = memberWithNull, MemberOnlyNull = memberOnlyNull,
        MemberPlain = memberPlain, MemberEmpty = memberEmpty
    ]
