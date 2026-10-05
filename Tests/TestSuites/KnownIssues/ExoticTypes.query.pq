// Type contract at the edges (all behaviors verified against the live reader):
// - UInt64 above 2^63-1 loads exactly and equality on the max value returns the right row:
//   the DECIMAL declaration + CAST literal writer make the engine DECLINE folding such
//   comparisons (evaluated client-side, exact) instead of folding them through DOUBLE and
//   silently returning 0 rows as the BIGINT declaration did. In-int64-range literals still
//   fold exactly (see BigIntEquality).
// - Enum and IPv4 surface as their numeric representations (server sends codes over Arrow).
// - Array loads as a real M list (declared metadata is the text fallback).
// - FixedString and UUID crash the ADBC reader (Arrow fixed_size_binary), so the connector
//   EXCLUDES those columns (fs, uid missing from Cols) instead of failing the table.
(source) =>
let
    t = source[exotic],
    b = Table.Buffer(t){0}
in
    [
        Cols = Text.Combine(Table.ColumnNames(t), ","),
        U64 = Text.From(b[u64]),
        U64Filter = Table.RowCount(Table.Buffer(Table.SelectRows(t, each [u64] = 18446744073709551615))),
        En = b[en],
        Ip = b[ip],
        Arr = Text.Combine(List.Transform(b[arr], Text.From), ",")
    ]
