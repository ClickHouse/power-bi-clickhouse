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
    // Literal precision: 19 significant digits exceed double precision, so this comparison
    // involves a decimal-typed constant. The engine declines to fold such comparisons (the
    // DECIMAL literal writer emits a CAST, which fold validation rejects) and evaluates them
    // client-side with full precision — this member guards that the result stays exact and
    // never silently matches 0 rows through a truncated server-side literal.
    lit18 = Table.RowCount(Table.Buffer(Table.SelectRows(source[decimals], each [d18] = 1.123456789012345678))),
    pick = (t) => Table.SelectRows(t, each [rid] = 1){0}[c],
    op = Table.Buffer(Table.AddColumn(d, "c", each [a] / [b], type number)),
    vdef = Table.Buffer(Table.AddColumn(d, "c", each Value.Divide([a], [b]), type number)),
    vdbl = Table.Buffer(Table.AddColumn(d, "c", each Value.Divide([a], [b], Precision.Double), type number)),
    vdec = Table.Buffer(Table.AddColumn(d, "c", each Value.Divide([a], [b], Precision.Decimal), type number)),
    dfrom = Table.Buffer(Table.AddColumn(d, "c", each Double.From([a]) / Double.From([b]), type number))
in
    [
        Op = pick(op), DefaultDiv = pick(vdef), DoubleDiv = pick(vdbl),
        DecimalDiv = pick(vdec), DoubleFrom = pick(dfrom), Literal18Digits = lit18
    ]
