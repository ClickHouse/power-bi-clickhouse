// Equality filter on an integer column folds and returns exactly the matching row.
(source) =>
let
    filtered = Table.SelectRows(source[numbers], each [i64] = 10000000000),
    buffered = Table.Buffer(filtered)
in
    [
        Rows = Table.RowCount(buffered),
        Rid  = buffered{0}[rid]
    ]
