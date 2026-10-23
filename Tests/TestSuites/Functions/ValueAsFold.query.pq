// Value.As type assertions pass through the generator only when statically satisfied (no SQL
// emitted for satisfied asserts). An INCOMPATIBLE assertion must keep M's failure behavior:
// the generator declines the fold and local evaluation raises the type error (a broken guard
// would silently return the number instead — the BadAssertIsError member catches that).
(source) =>
let
    t = Table.Buffer(Table.SelectRows(
        Table.AddColumn(source[numbers], "va", each Value.As([i32], type nullable number), type number),
        each [rid] = 4)){0},
    bad = try Table.Buffer(Table.SelectRows(
        Table.AddColumn(source[numbers], "bad", each Value.As([i32], type nullable text)),
        each [rid] = 4)){0}[bad]
in
    [VA = t[va], BadAssertIsError = bad[HasError]]
