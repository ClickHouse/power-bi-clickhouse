// A table with a plain DateTime column must LOAD (server sends raw uint32 epoch seconds over
// Arrow, so the column is surfaced as Int64 epoch — not a failing datetime). DateTime64 in the
// same table stays a real datetime. Revisit when the server emits proper timestamps.
(source) =>
let
    t = Table.Buffer(Table.Sort(source[datetimes], {{"rid", Order.Ascending}}))
in
    [
        Rows = Table.RowCount(t),
        DtEpoch = t{0}[dt],   // 2024-02-29 12:30:45 UTC as epoch seconds
        Dt64Text = DateTime.ToText(t{0}[dt64], [Format = "yyyy-MM-dd HH:mm:ss"])
    ]
