// The bootstrap requests an explicit database, so the navigator must list ONLY that database
// (no system/alias leakage). The browse-all behavior (aliases hidden, system kept) is verified
// manually with a null-database source; it cannot live in the suite without a hardcoded server.
(source) =>
let
    names = source[Source][Name]
in
    [
        HasPqtest = List.Contains(names, "pqtest"),
        HasSystem = List.Contains(names, "system"),
        InfoSchemaHidden = not List.Contains(names, "INFORMATION_SCHEMA") and not List.Contains(names, "information_schema")
    ]
