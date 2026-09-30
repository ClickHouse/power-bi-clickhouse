// Explicit M precision requests must be honored in folded arithmetic (a, b are Decimal(9,3);
// row 1 is 1 / 1.3). ClickHouse Decimal division keeps the dividend's scale and truncates,
// so a pass-through would return 0.769 regardless of the requested precision:
// - Precision.Double (explicit or defaulted) folds as cast(... as DOUBLE) / cast(... as DOUBLE),
//   matching local M and the engine's own `/` operator coercion (Op control).
// - Precision.Decimal widens the dividend to Decimal(38, 10) for a defined scale
//   (M's 28-digit decimal is not reachable server-side — documented deviation).
// - Double.From on a Decimal column is a real conversion, not a no-op.
(source) =>
let
    d = source[division],
    pick = (t) => Table.SelectRows(t, each [rid] = 1){0}[c],
    op = Table.Buffer(Table.AddColumn(d, "c", each [a] / [b], type number)),
    vdef = Table.Buffer(Table.AddColumn(d, "c", each Value.Divide([a], [b]), type number)),
    vdbl = Table.Buffer(Table.AddColumn(d, "c", each Value.Divide([a], [b], Precision.Double), type number)),
    vdec = Table.Buffer(Table.AddColumn(d, "c", each Value.Divide([a], [b], Precision.Decimal), type number)),
    dfrom = Table.Buffer(Table.AddColumn(d, "c", each Double.From([a]) / Double.From([b]), type number))
in
    [
        Op = pick(op), DefaultDiv = pick(vdef), DoubleDiv = pick(vdbl),
        DecimalDiv = pick(vdec), DoubleFrom = pick(dfrom)
    ]
