(source) =>
let
    e = source[events],
    picked = Table.SelectRows(e, each List.Contains({3, 7, 11, 19, 23, 31, 42, 47, 53, 59, 61, 67, 71, 79, 83, 89}, [id])),
    bucketed = Table.AddColumn(picked, "bucket", each
        if [val] < 2 then "low" else if [val] < 5 then "mid" else if [val] < 8 then "high" else "top", type text),
    grouped = Table.Group(bucketed, {"bucket"},
        {{"total", each List.Sum([val]), type number},
         {"cnt", each Table.RowCount(_), Int64.Type}}),
    sorted = Table.Buffer(Table.Sort(grouped, {{"bucket", Order.Ascending}}))
in
    [
        Buckets = Table.RowCount(sorted),
        First = sorted{0}[bucket],
        GrandTotal = Number.Round(List.Sum(sorted[total]), 2)
    ]
