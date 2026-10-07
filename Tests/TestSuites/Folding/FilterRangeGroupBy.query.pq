// Range filter + group-by folds into a single server-side aggregation.
(source) =>
let
    filtered = Table.SelectRows(source[events], each [id] >= 50),
    grouped = Table.Group(filtered, {"name"}, {{"total", each List.Sum([val]), type number}, {"cnt", each Table.RowCount(_), Int64.Type}}),
    sorted = Table.Buffer(Table.Sort(grouped, {{"name", Order.Ascending}}))
in
    [
        Groups     = Table.RowCount(sorted),
        FirstName  = sorted{0}[name],
        FirstTotal = sorted{0}[total],
        FirstCnt   = sorted{0}[cnt]
    ]
