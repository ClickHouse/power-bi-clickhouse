// Distinct + row count folds (uniq/uniqExact path).
(source) =>
    [
        DistinctNames = Table.RowCount(Table.Buffer(Table.Distinct(Table.SelectColumns(source[events], {"name"})))),
        AllRows       = Table.RowCount(source[events])
    ]
