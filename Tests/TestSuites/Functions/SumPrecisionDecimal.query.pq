// An explicit Precision.Decimal on a floating column forces the parameterized decimal cast:
// SUM(cast("f64" as Decimal(38, 10))) — the emitted-cast path the DAX layer relies on.
(source) =>
let
    g = Table.Buffer(Table.Group(source[numbers], {},
        {{"s", each List.Sum([f64], Precision.Decimal), type number}})){0}
in
    [SumDecimalPrecision = g[s]]
