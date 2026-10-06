// Value.Compare folds as a searched CASE over < / > (-1 / 0 / 1). Subtraction-based
// folding (SIGN(a - b)) overflows at Int64 boundaries and collides values through DOUBLE —
// the Boundary members pin the exact behavior at the extremes.
(source) =>
let
    t = Table.AddColumn(source[numbers], "cmp", each Value.Compare([i32], [i16]), Int64.Type),
    t2 = Table.AddColumn(t, "cmp2", each Value.Compare([i64], [u64]), Int64.Type),
    b = Table.Buffer(Table.Sort(t2, {{"rid", Order.Ascending}}))
in
    [
        Less = b{0}[cmp],         // -2147483648 vs -32768                       -> -1
        Equal = b{2}[cmp],        // 1 vs 1                                      ->  0
        Greater = b{4}[cmp],      // 2147483647 vs 32767                         ->  1
        BoundaryMinVsZero = b{0}[cmp2],   // -9223372036854775808 vs 0           -> -1 (subtraction overflows)
        BoundaryEqual = b{3}[cmp2],       // 10000000000 vs 10000000000          ->  0
        BoundaryMaxVsUMax = b{4}[cmp2],   // 9223372036854775807 vs 2^64-1       -> -1 (subtraction overflows)
        // Distinct decimals that collapse to the SAME double: a comparison folded through
        // DOUBLE coercion returns 0 here; the CASE fold compares exactly.
        DoubleCollision = Table.Buffer(Table.AddColumn(source[decimals], "c", each Value.Compare([d18], [d18b]), Int64.Type)){0}[c]
    ]
