// Equality filter on a UInt64 value above 2^53 returns exactly the matching row.
// Regression guard for: DOUBLE coercion in folded comparisons (precision loss).
(source) =>
let
    hit = Table.Buffer(Table.SelectRows(source[big_ids], each [id] = 9007199254740993))
in
    [
        Rows  = Table.RowCount(hit),
        Label = hit{0}[label]  // expect "two_pow_53_plus_1"
    ]
