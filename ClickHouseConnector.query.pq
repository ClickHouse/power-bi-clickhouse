// Test query for the ClickHouse Arrow Flight connector
let
    result = ClickHouseArrowFlight.Database("localhost", 9005, "default")
in
    result
