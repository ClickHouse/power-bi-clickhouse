// MIN/MAX over date and text columns fold and keep their types (not just numeric MIN/MAX).
(source) =>
let
    grouped = Table.Group(source[dates], {},
        {{"minD", each List.Min([d]), type date},
         {"maxD", each List.Max([d]), type date}}),
    g = Table.Buffer(grouped){0},
    t = Table.Group(source[text], {},
        {{"maxS", each List.Max([s]), type text}}),
    ts = Table.Buffer(t){0}
in
    [
        MinDate = Date.ToText(g[minD], [Format = "yyyy-MM-dd"]),
        MaxDate = Date.ToText(g[maxD], [Format = "yyyy-MM-dd"]),
        MaxText = ts[maxS]
    ]
