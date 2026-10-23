// String literals containing apostrophes and backslashes fold into correctly escaped SQL:
// an equality filter on such a value must return exactly the matching row.
(source) =>
let
    tricky = "O'Brien \ C:\dir\name",
    hit = Table.Buffer(Table.SelectRows(source[text], each [s] = tricky)),
    quoteOnly = Table.Buffer(Table.SelectRows(source[text], each Text.Contains([s], "O'B")))
in
    [
        EqualityRows = Table.RowCount(hit),
        Rid = hit{0}[rid],
        ContainsRows = Table.RowCount(quoteOnly)
    ]
