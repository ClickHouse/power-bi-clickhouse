// Bootstrap for the ADBC / Arrow Flight SQL implementation (Implementation = "2.0").
// Adjust Server/Port to your ClickHouse instance and run Tests/Fixtures/seed.sql first.
let
    Server = "localhost",
    Port = 9007,
    Source = ClickHouse.Database(Server, Port, "pqtest", [Implementation = "2.0"]),
    Db = Source{[Name = "pqtest"]}[Data]
in
    [
        numbers  = Db{[Name = "numbers"]}[Data],
        dates    = Db{[Name = "dates"]}[Data],
        text     = Db{[Name = "text"]}[Data],
        division = Db{[Name = "division"]}[Data],
        big_ids  = Db{[Name = "big_ids"]}[Data],
        events   = Db{[Name = "events"]}[Data],
        nullable = Db{[Name = "nullable"]}[Data],
        datetimes = Db{[Name = "datetimes"]}[Data],
        unicode  = Db{[Name = "unicode"]}[Data],
        exotic   = Db{[Name = "exotic"]}[Data],
        Source   = Source
    ]
