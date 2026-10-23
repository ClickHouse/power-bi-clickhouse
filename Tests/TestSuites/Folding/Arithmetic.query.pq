// Add / Subtract / Multiply fold as native operators (Divide is covered by DecimalDivision).
(source) =>
let
    t = Table.AddColumn(
        Table.AddColumn(
            Table.AddColumn(source[numbers], "plus", each [i32] + [i16], Int64.Type),
            "minus", each [i32] - [i16], Int64.Type),
        "times", each [f64] * 2, type number),
    r4 = Table.Buffer(Table.SelectRows(t, each [rid] = 4)){0}
in
    [Plus = r4[plus], Minus = r4[minus], Times = r4[times]]
