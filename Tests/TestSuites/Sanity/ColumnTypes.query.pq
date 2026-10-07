// Column types survive the ADBC path: numeric/text/date columns land as the expected M types.
(source) =>
let
    numbers = source[numbers],
    schema = Table.Schema(numbers),
    kindOf = (col as text) => Table.SelectRows(schema, each [Name] = col){0}[Kind]
in
    [
        I64Kind  = kindOf("i64"),
        F64Kind  = kindOf("f64"),
        DecKind  = kindOf("dec92"),
        DateKind = Table.SelectRows(Table.Schema(source[dates]), each [Name] = "d"){0}[Kind],
        TextKind = Table.SelectRows(Table.Schema(source[text]), each [Name] = "s"){0}[Kind]
    ]
