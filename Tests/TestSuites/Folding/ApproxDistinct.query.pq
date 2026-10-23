// Approximate distinct count inside a group-by folds to uniq(col) per group.
(source) =>
let
    grouped = Table.Group(source[events], {"name"},
        {{"days", each Table.ApproximateRowCount(Table.Distinct(Table.SelectColumns(_, {"d"}))), Int64.Type}}),
    buffered = Table.Buffer(Table.Sort(grouped, {{"name", Order.Ascending}}))
in
    [Groups = Table.RowCount(buffered), FirstDays = buffered{0}[days]]
