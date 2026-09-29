// Text function coverage: Upper/Lower/Length/PositionOf/StartsWith (DirectQuery function list).
(source) =>
let
    t = Table.Buffer(Table.Sort(source[text], {{"rid", Order.Ascending}})),
    hello = t{0}[s]
in
    [
        Upper    = Text.Upper(hello),
        Lower    = Text.Lower(hello),
        Len      = Text.Length(hello),
        Pos      = Text.PositionOf(hello, "World"),
        Starts   = Text.StartsWith(hello, "Hello"),
        EmptyLen = Text.Length(t{2}[s])
    ]
