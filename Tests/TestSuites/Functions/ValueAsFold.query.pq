// Value.As type assertions pass through the generator (no SQL emitted for satisfied asserts).
(source) =>
let
    t = Table.Buffer(Table.SelectRows(
        Table.AddColumn(source[numbers], "va", each Value.As([i32], type nullable number), type number),
        each [rid] = 4)){0}
in
    [VA = t[va]]
