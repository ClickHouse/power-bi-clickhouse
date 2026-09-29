// The List.Count(List.Distinct(col)) spelling of distinct count folds to uniqExact per group
// (the Table.RowCount(Table.Distinct(...)) spelling is covered by GroupDistinctCount).
(source) =>
let
    grouped = Table.Group(source[events], {"name"},
        {{"days", each List.Count(List.Distinct([d])), Int64.Type}}),
    b = Table.Buffer(Table.Sort(grouped, {{"name", Order.Ascending}}))
in
    [Groups = Table.RowCount(b), FirstDays = b{0}[days]]
