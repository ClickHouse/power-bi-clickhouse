// Value.Compare folds as SIGN(a - b): -1 / 0 / 1 for less / equal / greater.
(source) =>
let
    t = Table.AddColumn(source[numbers], "cmp", each Value.Compare([i32], [i16]), Int64.Type),
    b = Table.Buffer(Table.Sort(t, {{"rid", Order.Ascending}}))
in
    [
        Less = b{0}[cmp],     // -2147483648 vs -32768  -> -1
        Equal = b{2}[cmp],    // 1 vs 1                 ->  0
        Greater = b{4}[cmp]   // 2147483647 vs 32767    ->  1
    ]
