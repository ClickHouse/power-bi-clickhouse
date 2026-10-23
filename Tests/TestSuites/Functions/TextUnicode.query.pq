// Text folding must be character-aware, not byte-aware (unicode.s holds multi-byte UTF-8:
// é = 2 bytes, 🎉 = 4 bytes). Byte-based position('éx', 'x') says 2 where M says 1; the
// generator folds to the *UTF8 function family (positionUTF8/lengthUTF8/leftUTF8/rightUTF8/
// lowerUTF8/upperUTF8). Note: lowerUTF8/upperUTF8 require a ClickHouse build with ICU (all
// stock releases have it).
(source) =>
let
    u = source[unicode],
    posx = Table.Buffer(Table.AddColumn(u, "c", each Text.PositionOf([s], "x"), Int64.Type)),
    len = Table.Buffer(Table.AddColumn(u, "c", each Text.Length([s]), Int64.Type)),
    st = Table.Buffer(Table.AddColumn(u, "c", each Text.Start([s], 2), type text)),
    en = Table.Buffer(Table.AddColumn(u, "c", each Text.End([s], 4), type text)),
    lo = Table.Buffer(Table.AddColumn(u, "c", each Text.Lower([s]), type text)),
    up = Table.Buffer(Table.AddColumn(u, "c", each Text.Upper([s]), type text)),
    pick = (t, r) => Table.SelectRows(t, each [rid] = r){0}[c]
in
    [
        PosAccent = pick(posx, 1),   // "éx": x is char 1 (0-based); byte position would say 2
        PosEmoji = pick(posx, 3),    // "a🎉x": x is char 2; byte position would say 5
        LenAccent = pick(len, 1),    // 2 chars (3 bytes)
        LenEmoji = pick(len, 3),     // 3 chars (6 bytes)
        StartAccent = pick(st, 2),   // first 2 chars of "ÉXAMPLE café"
        EndAccent = pick(en, 2),     // last 4 chars
        LowerAccent = pick(lo, 2),
        UpperAccent = pick(up, 1)
    ]
