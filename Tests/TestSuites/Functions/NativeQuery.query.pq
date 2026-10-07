// Value.NativeQuery runs raw SQL verbatim — including ClickHouse-specific functions and
// SETTINGS clauses that folded queries can never express.
(source) =>
let
    agg = Table.Buffer(Value.NativeQuery(source[Source],
        "SELECT name, round(sum(val), 2) AS total FROM pqtest.events WHERE id < 20 GROUP BY name ORDER BY name LIMIT 2")),
    settings = Table.Buffer(Value.NativeQuery(source[Source],
        "SELECT uniqExact(name) AS u FROM pqtest.events SETTINGS max_threads = 1"))
in
    [
        FirstName = agg{0}[name],
        FirstTotal = agg{0}[total],
        Rows = Table.RowCount(agg),
        UniqWithSettings = settings{0}[u]
    ]
