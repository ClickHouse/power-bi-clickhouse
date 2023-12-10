// Use this file to write queries to test your data connector
let
    result = ClickHouse.Contents("localhost",8123,"default")
in
    result