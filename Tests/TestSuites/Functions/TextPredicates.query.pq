// Text.Contains / StartsWith / EndsWith fold as filters (position / startsWith / endsWith).
(source) =>
    [
        ContainsRows = Table.RowCount(Table.Buffer(Table.SelectRows(source[text], each Text.Contains([s], "World")))),
        StartsRows   = Table.RowCount(Table.Buffer(Table.SelectRows(source[text], each Text.StartsWith([s], "Case")))),
        EndsRows     = Table.RowCount(Table.Buffer(Table.SelectRows(source[text], each Text.EndsWith([s], "c"))))
    ]
