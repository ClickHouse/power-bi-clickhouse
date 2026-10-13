// ClickHouse Arrow Flight connector for Power BI (Beta).
// A dedicated, Flight-SQL-only connector: it talks to ClickHouse's Arrow Flight SQL
// interface (arrowflight_port) through the Microsoft-distributed ADBC driver, with
// DirectQuery folding provided by ClickHouseSqlGenerator.pqm. The classic ODBC connector
// ("ClickHouseArrowFlight") is a separate, unchanged connector.
[Version = "1.0.0"]
section ClickHouseArrowFlight;
ConnectorVersion = "1.0.0";

// When set to true, additional trace information will be written out to the User log.
EnableTraceOutput = false;

Config_EnableDirectQuery = true;

[DataSource.Kind = "ClickHouseArrowFlight", Publish = "ClickHouseArrowFlight.Publish"]
shared ClickHouseArrowFlight.Database = Value.ReplaceType(DatabaseCoreImplementation, DatabaseType);

DatabaseType = type function (
    server as (type text meta [
        Documentation.FieldCaption = "Server",
        Documentation.FieldDescription = "ClickHouse server host name (name only, without prefixes)",
        Documentation.SampleValues = {"my-server.clickhouse.cloud"}
    ]),
    port as (type number meta [
        Documentation.FieldCaption = "Port",
        Documentation.FieldDescription = "The server's Arrow Flight SQL port (arrowflight_port)",
        Documentation.SampleValues = {9005}
    ]),
    optional database as (type text meta [
        Documentation.FieldCaption = "Database",
        Documentation.FieldDescription = "Name of ClickHouse database",
        Documentation.SampleValues = {"default"}
    ]),
    optional options as (type record meta [
        Documentation.FieldCaption = "Options",
        Documentation.FieldDescription = "Optional record: HighPrecision (default true: ClickHouse Decimal stays exact in aggregates; false: downcast to double); SSLMode (""none"" connects WITHOUT encryption — explicit opt-out; connections are encrypted by default)"
    ]))
    as table meta [
        Documentation.Name = "ClickHouse Arrow Flight",
        Documentation.LongDescription = "Connects to a ClickHouse server over Arrow Flight SQL (gRPC, encrypted by default) and returns a foldable navigation table. Requires a ClickHouse server with the Arrow Flight SQL interface enabled (arrowflight_port) and Power BI Desktop 2.155 or later. Known limitations: plain DateTime columns surface as Int64 epoch seconds (use DateTime64), outer merges are evaluated by Power Query rather than folded, and per-connection server settings are not yet supported.",
        Documentation.Examples = {[
            Description = "Connects over Arrow Flight SQL to the server's arrowflight_port",
            Code = "ClickHouseArrowFlight.Database(""my-server"", 9005)"
        ]}
    ];

ValidOptionsMap = #table(
    {"Name", "Type", "Description", "Default", "Validate"},
    {
        {
            // true (default) keeps ClickHouse Decimal columns exact in SUM/arithmetic
            // (SUM("amount") -> Decimal); false downcasts to Float64 to match Power Query's
            // default local-eval semantics (SUM(cast(... AS DOUBLE))).
            "HighPrecision",
            type nullable logical,
            "Keep Decimal exact in aggregates/arithmetic (true, default) vs downcast to double (false)",
            true,
            each _ = null or _ = true or _ = false
        },
        {
            // Explicit opt-out from TLS for plaintext dev servers; see the Encrypt logic in
            // ClickHouseAdbcConnection for the credential-precedence rules.
            "SSLMode",
            type nullable text,
            "Set to none to connect WITHOUT encryption (explicit opt-out; encrypted by default)",
            null,
            each _ = null or _ = "none"
        }
    }
);

DatabaseCoreImplementation = (server as text, port as number, optional database as text, optional options as record) =>
    let
        ValidatedOptions = ValidateOptions(options, ValidOptionsMap)
    in
        ClickHouseAdbcConnection(server, port, database, ValidatedOptions[HighPrecision]?, ValidatedOptions[SSLMode]?);

ClickHouseArrowFlight = [
    // Set the TestConnection handler to enable gateway support.
    // The TestConnection handler will invoke your data source function to
    // validate the credentials the user has provider. Ideally, this is not
    // an expensive operation to perform. By default, the dataSourcePath value
    // will be a json string containing the required parameters of your data
    // source function. These should be parsed and parsed as individual parameters
    // to the specified data source function.
    // Optional parameters are excluded from the data-source path; the handler validates the
    // credential with an authenticated Flight SQL metadata call.
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            server = json[server],
            port = json[port],
            database = try json[database] otherwise null
        in
            {"ClickHouseArrowFlight.ValidateConnection", server, port, database},
    // Set supported types of authentication
    Authentication = [
        //Windows = [],
        UsernamePassword = []
    ],
    SupportsEncryption = true,
    Label = Extension.LoadString("DataSourceLabel")
];

// Credential validation for TestConnection (gateway/service refresh). Flight-only: the probe
// is an authenticated metadata call over Arrow Flight SQL; every failure surfaces as-is
// (there is no second transport to fall back to in this connector).
[DataSource.Kind = "ClickHouseArrowFlight"]
shared ClickHouseArrowFlight.ValidateConnection = (server as text, port as number, optional database as text) as number =>
    Table.RowCount(ClickHouseAdbcConnection(server, port, database, null, null));

ClickHouseArrowFlight.Publish = [
    // This connector is the Beta home of the Arrow Flight SQL implementation; the classic
    // ODBC connector ("ClickHouse") remains the GA product.
    Beta = true,
    Category = "Database",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://clickhouse.com",
    SupportsDirectQuery = Config_EnableDirectQuery,
     SourceImage = ClickHouseArrowFlight.Icons,
     SourceTypeImage = ClickHouseArrowFlight.Icons
];

ClickHouseArrowFlight.Icons = [
    Icon16 = {
        Extension.Contents("ClickHouseConnector16.png"),
        Extension.Contents("ClickHouseConnector20.png"),
        Extension.Contents("ClickHouseConnector24.png"),
        Extension.Contents("ClickHouseConnector32.png")
    },
    Icon32 = {
        Extension.Contents("ClickHouseConnector32.png"),
        Extension.Contents("ClickHouseConnector40.png"),
        Extension.Contents("ClickHouseConnector48.png"),
        Extension.Contents("ClickHouseConnector64.png")
    }
];



ValidateOptions = (options as nullable record, validOptionsMap as table) as record =>
    let
        ValidKeys = Table.Column(validOptionsMap, "Name"),
        InvalidKeys = List.Difference(Record.FieldNames(options), ValidKeys),
        InvalidKeysText =
            if List.IsEmpty(InvalidKeys) then
                null
            else
                Text.Format(
                    "'#{0}' are not valid options. Valid options are: '#{1}'",
                    {Text.Combine(InvalidKeys, ", "), Text.Combine(ValidKeys, ", ")}
                ),
        ValidateValue = (name, optionType, description, default, validate, value) =>
            if
                (value is null and (Type.IsNullable(optionType) or default <> null))
                or (Type.Is(Value.Type(value), optionType) and validate(value))
            then
                null
            else
                Text.Format(
                    "This function does not support the option '#{0}' with value '#{1}'. Valid value is #{2}.",
                    {name, value, description}
                ),
        InvalidValues = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    ValidateValue(
                        [Name],
                        [Type],
                        [Description],
                        [Default],
                        [Validate],
                        Record.FieldOrDefault(options, [Name], [Default])
                    )
            )
        ),
        DefaultOptions = Record.FromTable(
            Table.RenameColumns(Table.SelectColumns(validOptionsMap, {"Name", "Default"}), {"Default", "Value"})
        ),
        NullNotAllowedFields = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    if not Type.IsNullable([Type]) and null = Record.FieldOrDefault(options, [Name], [Default]) then
                        [Name]
                    else
                        null
            )
        ),
        NormalizedOptions = DefaultOptions & Record.RemoveFields(options, NullNotAllowedFields, MissingField.Ignore)
    in
        if null = options then
            DefaultOptions
        else if not List.IsEmpty(InvalidKeys) then
            error Error.Record("Expression.Error", InvalidKeysText)
        else if not List.IsEmpty(InvalidValues) then
            error Error.Record("Expression.Error", Text.Combine(InvalidValues, ", "))
        else
            NormalizedOptions;

//
// Load common library functions
//

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");

Diagnostics.LogValue = if (EnableTraceOutput) then Diagnostics[LogValue] else (prefix, value) => value;

// Load a module file as an M expression (used for the SQL generator).
Extension.LoadExpression = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Adbc.Connection is provided by the host mashup engine. Resolve defensively so the
// connector loads with a clear error where it is unavailable (older hosts).
Adbc.Connection =
    try
        #shared[Adbc.Connection]
    otherwise
        (driver, connectionString, properties, options) =>
            error Error.Record("Expression.Error", "The Adbc.Connection function is not available in this environment");

// SqlView.Generator turns a table reference + its (explicitly derived) type into a foldable
// Table.View that pushes Power Query operations down into ClickHouse SQL via ClickHouseSqlGenerator.
SqlView.Generator =
    try
        #shared[SqlView.Generator]
    otherwise
        (uniqueId, sqlGenerator, getData) =>
            error Error.Record("Expression.Error", "The SqlView.Generator function is not available in this environment");

// ClickHouse SQL dialect overrides (Sql92 base + ClickHouse), consumed by SqlView.Generator.
ClickHouseSqlGenerator = Extension.LoadExpression("ClickHouseSqlGenerator.pqm");


Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            Preview.DelayColumn = itemNameColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ]
    in
        Value.ReplaceType(table, newTableType);

// Backtick-quote a ClickHouse identifier.
ChQuote = (name as text) as text => "`" & Text.Replace(name, "`", "``") & "`";

// Strip LowCardinality(...)/Nullable(...) wrappers from a DESCRIBE type string; returns
// [Base = inner type, IsNullable = logical].
UnwrapChType = (chType as text) as record =>
    let
        t0 = Text.Trim(chType),
        t1 = if Text.StartsWith(t0, "LowCardinality(") then Text.Range(t0, 15, Text.Length(t0) - 16) else t0,
        isNullable = Text.StartsWith(t1, "Nullable(")
    in
        [Base = Text.Trim(if isNullable then Text.Range(t1, 9, Text.Length(t1) - 10) else t1), IsNullable = isNullable];

// Types the ADBC reader cannot fetch: FixedString/UUID/IPv6 and the 128/256-bit integers
// arrive as Arrow fixed_size_binary and crash the result reader (verified — the failure is
// not catchable with try); Decimal with precision > 38 is Arrow decimal256, which the driver
// rejects and fails the whole table; JSON/Dynamic/Variant break the Arrow binary fallback.
// Columns of these types are EXCLUDED from the table (traced below) instead of failing the
// load — reach them through Value.NativeQuery with an explicit server-side conversion,
// e.g. SELECT toString(fixed_string_col) ...
IsUnsupportedChType = (chType as text) as logical =>
    let
        b = UnwrapChType(chType)[Base],
        dec = if Text.StartsWith(b, "Decimal(") then
                  try Number.FromText(Text.Trim(Text.BeforeDelimiter(Text.Range(b, 8, Text.Length(b) - 9), ","))) otherwise null
              else null
    in
        Text.StartsWith(b, "FixedString")
        or List.Contains({"UUID", "IPv6", "Int128", "UInt128", "Int256", "UInt256", "JSON", "Dynamic", "Variant"}, b)
        or Text.StartsWith(b, "JSON(") or Text.StartsWith(b, "Dynamic(") or Text.StartsWith(b, "Variant(")
        or Text.StartsWith(b, "AggregateFunction")
        or (dec <> null and dec > 38);

// Map a ClickHouse type string (as returned by DESCRIBE TABLE) to a Power Query M type,
// WITH a NativeTypeName facet that matches a SqlTypeName in ClickHouseSqlGenerator's
// SqlGetTypeInfo. SqlView.Generator uses that facet to map each column to a SQL type for
// folding/round-tripping; without it folding fails with "Unable to understand the type".
// Verified against ClickHouse 26.5+ by value-level probes (see Tests/COVERAGE.md).
MapClickHouseType = (chType as text) as type =>
    let
        unwrapped = UnwrapChType(chType),
        isNullable = unwrapped[IsNullable],
        b = unwrapped[Base],
        spec =
            // UInt64 must be DECIMAL, not BIGINT: values above 2^63-1 load exactly, but a
            // BIGINT declaration makes the engine coerce out-of-range filter literals through
            // DOUBLE (verified: WHERE cast(v as DOUBLE) = 1.84467440737096E19 -> 0 rows,
            // silently wrong). DECIMAL keeps literals exact end to end.
            if b = "UInt64" then [m = Decimal.Type, n = "DECIMAL"]
            else if Text.StartsWith(b, "Decimal") then [m = Decimal.Type, n = "DECIMAL"]
            // DateTime64 arrives as a real Arrow timestamp; plain DateTime arrives as raw
            // uint32 epoch seconds (server-side Arrow writer gap), so declaring it datetime
            // would fail the whole load — surface it as a BIGINT of epoch seconds instead.
            else if Text.StartsWith(b, "DateTime64") then [m = type datetime, n = "TIMESTAMP"]
            else if Text.StartsWith(b, "DateTime") then
                Diagnostics.LogValue("MapClickHouseType: plain DateTime surfaced as epoch seconds", [m = Int64.Type, n = "BIGINT"])
            else if b = "Date" or b = "Date32" then [m = type date, n = "DATE"]
            else if b = "Float32" or b = "Float64" then [m = Double.Type, n = "DOUBLE"]
            // Known limitation: DAX "is False" filters on logical columns emit a shape the
            // engine refuses to fold before consulting the SQL generator (see the
            // List.Contains override), so they error in DirectQuery; "is True" folds.
            else if b = "Bool" then [m = type logical, n = "BOOLEAN"]
            else if List.Contains({"Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32"}, b) then [m = Int64.Type, n = "BIGINT"]
            // Enums arrive as their numeric codes over Arrow (verified: 'beta' = 2 loads as
            // 2), and ClickHouse compares enum columns to numbers server-side, so a numeric
            // declaration keeps values and folded filters consistent. Names need a
            // server-side toString (Value.NativeQuery).
            else if Text.StartsWith(b, "Enum") then
                Diagnostics.LogValue("MapClickHouseType: " & b & " surfaced as its numeric code", [m = Int64.Type, n = "BIGINT"])
            // IPv4 arrives as its uint32 value (verified: '1.2.3.4' loads as 16909060).
            else if b = "IPv4" then
                Diagnostics.LogValue("MapClickHouseType: IPv4 surfaced as its numeric value", [m = Int64.Type, n = "BIGINT"])
            else Diagnostics.LogValue("MapClickHouseType: unmapped type '" & b & "' falls back to", [m = type text, n = "VARCHAR"]),
        baseType = if isNullable then type nullable (spec[m]) else spec[m]
    in
        Type.ReplaceFacets(baseType, [NativeTypeName = spec[n]]);

// Build a FOLDABLE leaf table. Column types come from DESCRIBE TABLE (not the missing server
// catalog); SqlView.Generator then pushes Power Query operations down into ClickHouse SQL.
ClickHouseLeafTable = (context as record, db as text, tbl as text) as table =>
    let
        described = Diagnostics.LogValue(
            "ClickHouseLeafTable: DESCRIBE " & db & "." & tbl,
            context[Exec]("DESCRIBE TABLE " & ChQuote(db) & "." & ChQuote(tbl), true)
        ),
        // Columns the ADBC reader cannot fetch are excluded (see IsUnsupportedChType) so the
        // rest of the table stays loadable; the exclusion is traced with column names.
        unsupported = Table.SelectRows(described, each IsUnsupportedChType([type])),
        supported =
            if Table.IsEmpty(unsupported) then described
            else Diagnostics.LogValue(
                "ClickHouseLeafTable: excluding unsupported column(s) from " & db & "." & tbl
                    & ": " & Text.Combine(unsupported[name], ", "),
                Table.SelectRows(described, each not IsUnsupportedChType([type]))),
        colNames = supported[name],
        colTypes = supported[type],
        fields = Record.FromList(
            List.Transform(colTypes, each [Type = MapClickHouseType(_), Optional = false]),
            colNames
        ),
        tableType = type table (Type.ForRecord(fields, false)),
        // Schema = ClickHouse database (no catalog level); generates "db"."tbl" in the FROM clause.
        tableReference = [Kind = "FromTable", Table = [Catalog = null, Schema = db, Name = tbl]]
    in
        context[FoldGen](tableReference, tableType, []);

// Tables within one database -> navigation table.
ClickHouseTablesNav = (context as record, db as text) as table =>
    let
        tables = Table.RenameColumns(context[Exec]("SHOW TABLES FROM " & ChQuote(db), true), {{"name", "Name"}}),
        withData = Table.AddColumn(tables, "Data", each ClickHouseLeafTable(context, db, [Name]), type table),
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Table", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Table", type text),
        withIsLeaf = Table.AddColumn(withItemName, "IsLeaf", each true, type logical)
    in
        Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf");

// Databases -> navigation table (filtered to the requested database when supplied).
ClickHouseDatabasesNav = (context as record, optional database as nullable text) as table =>
    let
        databases = Table.RenameColumns(context[Exec]("SHOW DATABASES", true), {{"name", "Name"}}),
        // Hide the INFORMATION_SCHEMA compatibility aliases from browsing (both spellings are
        // views over the same schema — duplicate noise); an explicitly requested database is
        // always honored, so they remain reachable via the Database parameter.
        filtered = Table.SelectRows(
            databases,
            each if database <> null then [Name] = database
                 else not List.Contains({"INFORMATION_SCHEMA", "information_schema"}, [Name])
        ),
        withData = Table.AddColumn(filtered, "Data", each ClickHouseTablesNav(context, [Name]), type table),
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Database", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Database", type text),
        withIsLeaf = Table.AddColumn(withItemName, "IsLeaf", each false, type logical)
    in
        Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf");

// ADBC entry point: open the Flight SQL connection, wire up folding, return the navigation table.
ClickHouseAdbcConnection = (server as text, port as number, optional database as text, optional highPrecision as logical, optional sslMode as text) as table =>
    let
        Driver = [
            Name = "FlightSqlClickHouse",
            Folder = "FlightSQL",
            File = "libadbc_driver_flightsql.dll",
            DriverType = "Unmanaged",
            EntryPoint = "FlightSqlDriverInit"
        ],
        Credential = Extension.CurrentCredential(),
        // Honor the encryption requirement from the credential: grpc+tls with the driver's
        // default certificate and hostname validation (system trust store). Absent an explicit
        // choice, default to encrypted. The connection is never SILENTLY downgraded to
        // plaintext. SSLMode=none in the connection options is the user-explicit opt-out
        // (Power BI Desktop exposes no UI for the credential's EncryptConnection flag on
        // custom connectors), but the CREDENTIAL always takes precedence: options live in the
        // report's M text and must not be able to downgrade a credential that explicitly
        // requires encryption — that combination raises a conflict error instead (clear the
        // data source's permissions or disable its encryption requirement to proceed).
        // Known limitation: TestConnection cannot see connection options (the data-source
        // path excludes them), so gateway credential validation probes encrypted-first and
        // fails against plaintext-only Flight endpoints configured via SSLMode=none.
        Encrypt =
            if sslMode = "none" then
                (if Credential[EncryptConnection]? = true then
                    error Error.Record("DataSource.Error",
                        "SSLMode=none conflicts with this credential's encrypted-connection requirement. Remove the option, or clear the data source permissions and store the credential without requiring encryption.",
                        null)
                 else false)
            else Credential[EncryptConnection]? ?? true,
        Scheme = if Encrypt then "grpc+tls://" else "grpc://",
        ConnectionString = [
            // NB: only the uri is traced here — credentials must never be logged.
            uri = Diagnostics.LogValue(
                "ClickHouseAdbcConnection: uri (database=" & (database ?? "<null>")
                    & ", highPrecision=" & (if highPrecision = false then "false" else "true") & ")",
                Scheme & server & ":" & Text.From(port)
            ),
            // Credentials ride on EVERY call as a static Basic authorization header instead of
            // the handshake-issued bearer token. The server's bearer tokens live in process
            // memory with a short idle TTL, so a pause or a server restart invalidates them —
            // and the pooled driver connection keeps presenting the dead token, forcing the
            // user to restart Power BI. The server authenticates every call anyway, so a
            // per-call Basic header costs nothing and survives idle time and restarts.
            // (On servers that still push a bearer on every response the driver adopts it and
            // behavior matches the old flow — no worse; servers with handshake-only token
            // minting keep the Basic header for the connection's lifetime.)
            #"adbc.flight.sql.authorization_header" =
                "Basic " & Binary.ToText(
                    Text.ToBinary(Credential[Username] & ":" & Credential[Password], TextEncoding.Utf8),
                    BinaryEncoding.Base64),
            // Cookie middleware (off by default in the driver) keeps pooled connections
            // working with servers that use Set-Cookie session affinity; harmless otherwise.
            #"adbc.flight.sql.rpc.with_cookie_middleware" = "true",
            // Client identification, recorded in system.query_log.client_name on servers that
            // read this header; older servers ignore unknown gRPC metadata (harmless).
            #"adbc.flight.sql.rpc.call_header.x-clickhouse-client-name" = "PowerBi/" & ConnectorVersion 
        ],
        Connection = Adbc.Connection(Driver, ConnectionString, [], [ConnectionPoolType = 2]),
        Exec = (sql as text, isMeta as logical) as table =>
            Connection[ExecuteQuery](
                Diagnostics.LogValue("ClickHouseAdbcConnection: ExecuteQuery" & (if isMeta then " (metadata)" else ""), sql),
                null,
                [IsMetadata = isMeta]
            ),
        // SqlView.Generator calls GetData with a folded SQL query + the computed result type;
        // we execute the SQL and align column names to the declared result type.
        GetData = (query as text, resultType as type, ctx) as table =>
            Table.View(null, [
                GetType = () => resultType,
                GetRows = () =>
                    let
                        data = Exec(query, false),
                        want = Table.ColumnNames(#table(resultType, {})),
                        have = Table.ColumnNames(data),
                        aligned =
                            if List.Count(have) = List.Count(want) and have <> want then
                                Table.RenameColumns(data, List.Zip({have, want}))
                            else
                                data
                    in
                        aligned
            ]),
        // Every option that changes SQL generation must be part of the key — the engine caches
        // the folding machinery by UniqueId, and two sources differing only in such an option
        // would otherwise share one cached generator.
        UniqueId = "clickhouse:" & server & ":" & Text.From(port) & ":" & (if database = null then "" else database)
            & ":hp=" & (if highPrecision = false then "0" else "1"),
        FoldGen = SqlView.Generator(UniqueId, ClickHouseSqlGenerator(highPrecision), GetData),
        context = [Exec = Exec, FoldGen = FoldGen],
        Nav = ClickHouseDatabasesNav(context, database)
    in
        // Value.NativeQuery(source, "...") support: run the statement verbatim on the server
        // (SETTINGS clauses and ClickHouse-specific functions included). Query parameters are
        // not supported yet: the engine rejects parameterized calls before reaching this handler
        // (verified); the null-check below is defense in depth.
        Table.View(Nav, [
            OnNativeQuery = (cmd, params, options) =>
                if params = null then Exec(cmd, false)
                else error Error.Record("Expression.Error", "Native query parameters are not supported yet."),
            ThrowFoldingFailures = false
        ]);
