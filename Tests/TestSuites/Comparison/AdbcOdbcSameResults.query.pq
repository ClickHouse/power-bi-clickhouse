// PQTest passes the parameter-query result to every test; accept and ignore it here
// (this test builds both sources itself).
(source) =>
// The ADBC (Implementation="2.0") and ODBC paths return the same answers for the same query.
// Adjust servers/ports to your environment; both must be seeded with Tests/Fixtures/seed.sql.
let
    Server = "localhost",
    AdbcPort = 9007,
    OdbcHttpPort = 8123,
    load = (options as record, port as number) =>
        let
            Db = ClickHouse.Database(Server, port, "pqtest", options){[Name = "pqtest"]}[Data],
            events = Db{[Name = "events"]}[Data],
            grouped = Table.Group(Table.SelectRows(events, each [id] >= 50), {"name"},
                {{"total", each List.Sum([val]), type number}})
        in
            Table.Buffer(Table.Sort(grouped, {{"name", Order.Ascending}})),
    adbc = load([Implementation = "2.0"], AdbcPort),
    odbc = load([], OdbcHttpPort)
in
    [
        SameGroupCount = Table.RowCount(adbc) = Table.RowCount(odbc),
        SameFirstTotal = Number.Round(adbc{0}[total], 6) = Number.Round(odbc{0}[total], 6),
        SameNames = Text.Combine(adbc[name], ",") = Text.Combine(odbc[name], ",")
    ]
