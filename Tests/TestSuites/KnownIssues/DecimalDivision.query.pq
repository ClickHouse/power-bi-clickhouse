// Decimal division keeps its fraction end to end (1 / 1.3 must not collapse to 1 or 0).
// Regression guard for: bare DECIMAL casts (scale 0) and double-based coercion.
(source) =>
let
    withRatio = Table.AddColumn(source[division], "ratio", each if [b] = 0 then null else [a] / [b], type number),
    buffered = Table.Buffer(Table.Sort(withRatio, {{"rid", Order.Ascending}})),
    r1 = buffered{0}[ratio]
in
    [
        Row1RatioRounded = Number.Round(r1, 3),  // expect 0.769
        Row2Ratio        = buffered{1}[ratio],   // expect 4
        Row3Ratio        = buffered{2}[ratio]    // expect 0 (0 / 1)
    ]
