// Double.From / Number.From on numeric columns fold (passthrough under HighPrecision).
(source) =>
let
    t = Table.AddColumn(
        Table.AddColumn(source[numbers], "df", each Double.From([i32]), type number),
        "nf", each Number.From([dec92]), type number),
    r4 = Table.Buffer(Table.SelectRows(t, each [rid] = 4)){0}
in
    [DF = r4[df], NF = r4[nf]]
