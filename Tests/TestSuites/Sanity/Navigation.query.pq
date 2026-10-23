// The navigation table exposes the pqtest database and its fixture tables.
(source) =>
let
    Db = source[Source]{[Name = "pqtest"]}[Data],
    TableNames = Db[Name]
in
    [
        HasNumbers  = List.Contains(TableNames, "numbers"),
        HasDivision = List.Contains(TableNames, "division"),
        HasEvents   = List.Contains(TableNames, "events")
    ]
