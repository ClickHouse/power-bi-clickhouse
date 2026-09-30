// Basic load: every fixture table materializes with the expected row count.
(source) =>
    [
        NumbersRows  = Table.RowCount(Table.Buffer(source[numbers])),
        DatesRows    = Table.RowCount(Table.Buffer(source[dates])),
        TextRows     = Table.RowCount(Table.Buffer(source[text])),
        DivisionRows = Table.RowCount(Table.Buffer(source[division])),
        BigIdsRows   = Table.RowCount(Table.Buffer(source[big_ids])),
        EventsRows   = Table.RowCount(Table.Buffer(source[events]))
    ]
