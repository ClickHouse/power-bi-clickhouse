// DirectQuery-enabled ClickHouse connector with two implementations selected via the
// options record: "1.0" (default) uses the ClickHouse ODBC driver over HTTP(S);
// "2.0" uses ADBC over Arrow Flight SQL (gRPC, TLS by default).
//
[Version = "1.2.0"]
section ClickHouse;
ConnectorVersion = "1.2.0";

// When set to true, additional trace information will be written out to the User log.
// This should be set to false before release. Tracing is done through a call to
// Diagnostics.LogValue(). When EnableTraceOutput is set to false, the call becomes a
// no-op and simply returns the original value.
EnableTraceOutput = false;

// TODO
// add handling for SSL
/****************************
 * ODBC Driver Configuration
 ****************************/
// The name of your ODBC driver.
//
Config_DriverNameUnicode = "ClickHouse ODBC Driver (Unicode)";
Config_DriverNameANSI = "ClickHouse ODBC Driver (ANSI)";

// If your driver under-reports its SQL conformance level because it does not
// support the full range of CRUD operations, but does support the ANSI SQL required
// to support the SELECT operations performed by Power Query, you can override
// this value to report a higher conformance level. Please use one of the numeric
// values below (i.e. 8 for SQL_SC_SQL92_FULL).
//
// SQL_SC =
// [
//     SQL_SC_SQL92_ENTRY            = 1,
//     SQL_SC_FIPS127_2_TRANSITIONAL = 2,
//     SQL_SC_SQL92_INTERMEDIATE     = 4,
//     SQL_SC_SQL92_FULL             = 8
// ]
//
// Set to null to determine the value from the driver.
//
Config_SqlConformance = ODBC[SQL_SC][SQL_SC_SQL92_FULL];
// null, 1, 2, 4, 8
// This setting controls row count limits and offsets. If not set correctly, query
// folding capabilities for this connector will be extremely limited. You can use
// the LimitClauseKind constants to match common LIMIT/OFFSET SQL formats. If none
// of the supported formats match your desired SQL syntax, consider filing a feature
// request to support your variation.
//
// Supporting OFFSET is considerably less important than supporting LIMIT.
//
// LimitClauseKind values and formats:
//
// LimitClauseKind.Top (LIMIT only, OFFSET not supported)
// -------------------
// SELECT TOP 100 *
// FROM table
//
// LimitClauseKind.Limit (LIMIT only, OFFSET not supported)
// ---------------------
// SELECT *
// FROM table
// LIMIT 100
//
// LimitClauseKind.LimitOffset
// ---------------------------
// SELECT *
// FROM table
// LIMIT 100 OFFSET 200
//
// This option requires that the SQL dialect support all three variations:
// "LIMIT x", "LIMIT x OFFSET y" and "OFFSET y". If your SQL dialect only supports
// OFFSET when LIMIT is also specified, use LimitClauseKind.Limit instead.
//
// LimitClauseKind.AnsiSql2008
// ---------------------------
// SELECT *
// FROM table
// OFFSET 200 ROWS
// FETCH FIRST 100 ROWS ONLY
//
Config_LimitClauseKind = LimitClauseKind.LimitOffset;
// see above
// Set this option to true if your ODBC supports the standard username/password
// handling through the UID and PWD connection string parameters. If the user
// selects UsernamePassword auth, the supplied values will be automatically
// added to the CredentialConnectionString.
//
// If you wish to set these values yourself, or your driver requires additional
// parameters to be set, please set this option to 'false'
//
Config_DefaultUsernamePasswordHandling = true;
// true, false
// Some drivers have problems will parameter bindings and certain data types.
// If the driver supports parameter bindings, then set this to true.
// When set to false, parameter values will be inlined as literals into the generated SQL.
// To enable inlining for a limited number of data types, set this value
// to null and set individual flags through the SqlCapabilities record.
//
// Set to null to determine the value from the driver.
//
Config_UseParameterBindings = null;
// true, false, null
// Override this setting to force the character escape value.
// This is typically done when you have set UseParameterBindings to false.
//
// Set to null to determine the value from the driver.
//
Config_StringLiterateEscapeCharacters = {"\"};
// ex. { "\" }
// Override this if the driver expects the use of CAST instead of CONVERT.
// By default, the query will be generated using ANSI SQL CONVERT syntax.
//
// Set to null to leave default behavior.
//
Config_UseCastInsteadOfConvert = null;
// true, false, null
// Set this to true to enable Direct Query in addition to Import mode.
//
Config_EnableDirectQuery = true;

// true, false
[DataSource.Kind = "ClickHouse", Publish = "ClickHouse.Publish"]
shared ClickHouse.Database = Value.ReplaceType(DatabaseCoreImplementation, DatabaseType);



// Documanting the function
DatabaseType = type function (
    server as (type text meta [
        Documentation.FieldCaption = "Server",
        Documentation.FieldDescription = "Name of ClickHouse Server (name only, without prefixes",
        Documentation.SampleValues = {"play.clickhouse.com"}
    ]),
     port as (type number meta [
        Documentation.FieldCaption = "Port",
        Documentation.FieldDescription = "Port used by ClickHouse: the HTTP(S) port for the default ODBC implementation, or the server's configured arrowflight_port for Implementation ""2.0"" (Arrow Flight SQL)",
        Documentation.SampleValues = {443, 8123, 8443, 9005}
    ]),
    optional database as (type text meta [
        Documentation.FieldCaption = "Database",
        Documentation.FieldDescription = "Name of ClickHouse database",
        Documentation.SampleValues = {"default"}
    ]),
    optional options as (type any meta [
        Documentation.FieldCaption = "Options",
        Documentation.FieldDescription = "Either ODBC connection-string options separated by semicolons, or an options record. Record options include Implementation (""1.0"" = ODBC, default; ""2.0"" = ADBC over Arrow Flight SQL) and, for ""2.0"", HighPrecision (default true: ClickHouse Decimal stays exact in aggregates; false: downcast to double)",
        Documentation.SampleValues = {"Timeout=600;UseUnicode=true","[Implementation = ""2.0""]"}
    ]))
    as table meta [
        Documentation.Name = "ClickHouse",
        Documentation.LongDescription = "Connects to a ClickHouse server and returns a foldable navigation table. Two implementations are available: the default (""1.0"") uses the ClickHouse ODBC driver over HTTP(S); Implementation ""2.0"" uses ADBC over Arrow Flight SQL (gRPC, encrypted by default) and requires a ClickHouse server with the Arrow Flight SQL interface enabled (arrowflight_port) and Power BI Desktop 2.155 or later. Known limitations of the Flight SQL path: plain DateTime columns surface as Int64 epoch seconds (use DateTime64), outer merges are evaluated by Power Query rather than folded, and per-connection server settings are not yet supported.",
         Documentation.Examples = {[
            Description = "Returns a navigation table with list of play.clickhouse.com tables, that can be folded",
            Code = "ClickHouse.Database(""https://play.clickhouse.com"")"
        ],[
            Description = "Connects over Arrow Flight SQL (ADBC) to the server's arrowflight_port",
            Code = "ClickHouse.Database(""my-server"", 9005, null, [Implementation = ""2.0""])"
        ]}
    ];



DatabaseCoreImplementation = (server as text, port as number, optional database as text, optional options as any) =>
let
        // Many data sources accept an optional 'options' record that allows users to change
        // default behaviors about the connection, such as connection timeout. Use this map
        // to define the appropriate options for your ODBC Driver. If you do not want to support
        // an options record, remove the ValidOptionsMap variable and options parameter from
        // the data source function.
        // more details regarding the driver options can be found at https://github.com/ClickHouse/clickhouse-odbc
        ValidOptionsMap = #table(
            {"Name", "Type", "Description", "Default", "Validate"},
            {
                {
                    "Timeout",
                    type nullable number,
                    "Connection timeout - positive integers only",
                    null,
                     each _ = null or (_ >= 0 and Number.RoundDown(_) = _)
                },
                {
                    "VerifyConnectionEarly",
                    type nullable text,
                    "Verify the connection and credentials during SQLConnect and similar calls (adds a typical overhead of one trivial remote query execution), otherwise, possible connection-related failures will be detected later, during SQLExecute and similar calls",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "SSLMode",
                    type nullable text,
                    "ODBC: certificate verification method (allow, prefer, require). ADBC (Implementation 2.0): set to none to connect WITHOUT encryption (explicit opt-out; connections are encrypted by default)",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "PrivateKeyFile",
                    type nullable text,
                    "Path to private key file (used by TLS/SSL connections)",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "CertificateFile",
                    type nullable text,
                    "Path to certificate file (used by TLS/SSL connections, ignored in Windows), if the private key and the certificate are stored in the same file, this can be empty if PrivateKeyFile is specified",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "CALocation",
                    type nullable text,
                    "Path to the file or directory containing the CA/root certificates (used by TLS/SSL connections, ignored in Windows)",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "HugeIntAsString",
                    type nullable text,
                    "Report integer column types that may underflow or overflow 64-bit signed integer (SQL_BIGINT) as a String/SQL_VARCHAR",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "DriverLog",
                    type nullable text,
                    "Enable or disable the extended driver logging",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "DriverLogFile",
                    type nullable text,
                    "Path to the extended driver log file (used when DriverLog is on)",
                    null,
                   each _ = null or _ <> null
                },
                {
                    "UseANSIDriver",
                    type nullable logical,
                    "By default, the unicode driver is used. Set this option to true for ANSI driver",
                    null,
                   each _ = null or _ <> null
                },
                {
                    // Selects the connector backend: "1.0" = ODBC (default, unchanged behavior),
                    // "2.0" = ADBC over Arrow Flight SQL. See ClickHouseAdbcDataSource below.
                    "Implementation",
                    type nullable text,
                    "Connector implementation: ""1.0"" for ODBC (default), ""2.0"" for ADBC Arrow Flight SQL",
                    "1.0",
                    each _ = null or _ = "1.0" or _ = "2.0"
                },
                {
                    // ADBC path only. true (default) keeps ClickHouse Decimal columns exact in
                    // SUM/arithmetic (SUM("amount") -> Decimal); false downcasts to Float64 to
                    // match Power Query's default local-eval semantics (SUM(cast(... AS DOUBLE))).
                    "HighPrecision",
                    type nullable logical,
                    "ADBC only: keep Decimal exact in aggregates/arithmetic (true, default) vs downcast to double (false)",
                    true,
                    each _ = null or _ = true or _ = false
                }




                // Some data sources may support setting separate timeout values for Connect and Command timeouts
                // {"CommandTimeout", type nullable number, "non-negative integers", null, each _ = null or (_ >= 0 and Number.RoundDown(_) = _)}
            }
        ),

        parsedOptions = if(Type.Is(Value.Type(options), type text))
                            then ConvertOptionsStringToRecord(options, ValidOptionsMap)
                        else if (Type.Is(Value.Type(options), type record))
                        then options
                        else [],

        ValidatedOptions = ValidateOptions(parsedOptions, ValidOptionsMap),
        //
        // Connection string settings
        //
        ConnectionString = [
            // At minimum you need to specify the ODBC Driver to use.
            Driver =  if(ValidatedOptions[UseANSIDriver]?=null or not ValidatedOptions[UseANSIDriver]?) then Config_DriverNameUnicode else Config_DriverNameANSI,
            // Specify custom properties for your ODBC Driver here.
            // The fields below are appropriate for the SQL Server ODBC Driver. The
            // names might be different for your data source.
            Server = server,

            Port = port ,
            Database = database,  
            // Identifies the implementation path server-side (system.query_log http_user_agent).
            // The ADBC path cannot send an equivalent yet: the Flight server does not read any
            // client-identity metadata (candidate server-side ask).
            ClientName = "PowerBi/" & ConnectorVersion & "-odbc",
            SQLCompatibilitySettings = 1,
            
            // These fields come from the options record, so they might be null.
            // A later step will strip all null values from the connection string.
            #"Timeout" = ValidatedOptions[Timeout]?,
            #"VerifyConnectionEarly" = ValidatedOptions[VerifyConnectionEarly]?,
            #"SSLMode" = ValidatedOptions[SSLMode]?,
            #"PrivateKeyFile" = ValidatedOptions[PrivateKeyFile]?,
            #"CertificateFile" = ValidatedOptions[CertificateFile]?,
            #"CALocation" = ValidatedOptions[CALocation]?,
            #"HugeIntAsString" = ValidatedOptions[HugeIntAsString]?,
            #"DriverLog" = ValidatedOptions[DriverLog]?,
            #"DriverLogFile" = ValidatedOptions[DriverLogFile]?

        ],
        //
        // Handle credentials
        // Credentials are not persisted with the query and are set through a separate
        // record field - CredentialConnectionString. The base Odbc.DataSource function
        // will handle UsernamePassword authentication automatically, but it is explictly
        // handled here as an example.
        //
        Credential = Extension.CurrentCredential(),
        CredentialConnectionString =
                [UID = Credential[Username], PWD = Credential[Password]],
          
        //
        // Configuration options for the call to Odbc.DataSource
        //
        defaultConfig = Diagnostics.LogValue("BuildOdbcConfig", BuildOdbcConfig()),
        SqlCapabilities = Diagnostics.LogValue(
            "SqlCapabilities_Options", defaultConfig[SqlCapabilities] & [
                // Place custom overrides here
                // The values below are required for the SQL Native Client ODBC driver, but might
                // not be required for your data source.
                FractionalSecondsScale = 3
            ]
        ),
        // Please refer to the ODBC specification for SQLGetInfo properties and values.
        // https://github.com/Microsoft/ODBC-Specification/blob/master/Windows/inc/sqlext.h
        SQLGetInfo = Diagnostics.LogValue(
            "SQLGetInfo_Options",
            defaultConfig[SQLGetInfo]
                & [
                    // Place custom overrides here
                    // The values below are required for the SQL Native Client ODBC driver, but might
                    // not be required for your data source.
                    SQL_SQL92_PREDICATES = ODBC[SQL_SP][All],
                    SQL_AGGREGATE_FUNCTIONS = ODBC[SQL_AF][All],
                    SQL_CONVERT_FUNCTIONS = 0x00000002 // Tell PowerBI that ClickHouse uses cast and not convert
                ]
        ),
        // SQLGetTypeInfo can be specified in two ways:
        // 1. A #table() value that returns the same type information as an ODBC
        //    call to SQLGetTypeInfo.
        // 2. A function that accepts a table argument, and returns a table. The
        //    argument will contain the original results of the ODBC call to SQLGetTypeInfo.
        //    Your function implementation can modify/add to this table.
        //
        // For details of the format of the types table parameter and expected return value,
        // please see: https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlgettypeinfo-function
        //
        // The sample implementation provided here will simply output the original table
        // to the user trace log, without any modification.
        SQLGetTypeInfo = (types) =>
            if (EnableTraceOutput <> true) then
                types
            else
                let
                    // Outputting the entire table might be too large, and result in the value being truncated.
                    // We can output a row at a time instead with Table.TransformRows()
                    rows = Table.TransformRows(types, each Diagnostics.LogValue("SQLGetTypeInfo " & _[TYPE_NAME], _)),
                    toTable = Table.FromRecords(rows)
                in
                    Value.ReplaceType(toTable, Value.Type(types)),
        // SQLColumns is a function handler that receives the results of an ODBC call
        // to SQLColumns(). The source parameter contains a table with the data type
        // information. This override is typically used to fix up data type mismatches
        // between calls to SQLGetTypeInfo and SQLColumns.
        //
        // For details of the format of the source table parameter, please see:
        // https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function
        //
        // The sample implementation provided here will simply output the original table
        // to the user trace log, without any modification.
        SQLColumns = (catalogName, schemaName, tableName, columnName, source) =>
            let
                    OdbcSqlType.BIT = -7,
                    OdbcSqlType.BOOLEAN = 249,
                    OdbcSqlType.SQL_GUID = -11,
                    OdbcSqlType.UUID = 245,
                    OdbcSqlType.SQL_TINYINT = -6,
                    OdbcSqlType.INT8 = 250,
                    OdbcSqlType.SQL_BIGINT = -5,
                    OdbcSqlType.INT64 = 251,
                    FixDataType = (dataType) =>
                        if dataType = OdbcSqlType.BOOLEAN then
                            OdbcSqlType.BIT
                        else if dataType = OdbcSqlType.UUID then
                            OdbcSqlType.SQL_GUID
                        else if dataType = OdbcSqlType.INT8 then
                            OdbcSqlType.SQL_TINYINT                            
                        else if dataType = OdbcSqlType.INT64 then
                            OdbcSqlType.SQL_BIGINT
                        else
                            dataType,
                    FixDataTypeName = (dataTypeName) =>
                        if dataTypeName = "TEXT" then
                            "SQL_WVARCHAR"
                        else if dataTypeName = "CHAR" then
                            "SQL_WCHAR"
                        else
                            dataTypeName,
                    Transform = Table.TransformColumns(source, {{"DATA_TYPE", FixDataType}
//                     , {"TYPE_NAME", FixDataTypeName}
                    })
           in
                    if (EnableTraceOutput <> true) then
                        Transform
                    else if (
                        // the if statement conditions will force the values to evaluated/written to diagnostics
                        Diagnostics.LogValue("SQLColumns.TableName", tableName) <> "***"
                        and Diagnostics.LogValue("SQLColumns.ColumnName", columnName) <> "***"
                    ) then
                        let
                            // Outputting the entire table might be too large, and result in the value being truncated.
                            // We can output a row at a time instead with Table.TransformRows()
                            rows = Table.TransformRows(Transform, each Diagnostics.LogValue("SQLColumns", _)),
                            toTable = Table.FromRecords(rows)
                        in
                            Value.ReplaceType(toTable, Value.Type(Transform))
                    else
                        Transform,
        // Remove null fields from the ConnectionString
        ConnectionStringNoNulls = Record.SelectFields(
            ConnectionString, Table.SelectRows(Record.ToTable(ConnectionString), each [Value] <> null)[Name]
        ),
        OdbcDatasource = Odbc.DataSource(
            ConnectionStringNoNulls,
            [
                // A logical (true/false) that sets whether to view the tables grouped by their schema names
                HierarchicalNavigation = true,
                // Allows upconversion of numeric types
                SoftNumbers = true,
                // Allow upconversion / resizing of numeric and string types
                TolerateConcatOverflow = true,
                // Enables connection pooling via the system ODBC manager
                ClientConnectionPooling = true,
                // These values should be set by previous steps
                CredentialConnectionString = CredentialConnectionString,
                SqlCapabilities = SqlCapabilities,
                SQLColumns = SQLColumns,
                SQLGetInfo = SQLGetInfo,
                SQLGetTypeInfo = SQLGetTypeInfo
            ]
        ),
        // without this filter, the user will get all databases
       OdbcDatasourceForSelectedDatabase = Table.SelectRows(OdbcDatasource, each [Name] = database or database = null)
    in
        // Dual implementation: "2.0" routes to the ADBC / Arrow Flight SQL path, anything else
        // (incl. the default "1.0") keeps the existing ODBC path. M's lazy evaluation means the
        // ODBC bindings above are not evaluated when the ADBC branch is taken.
        if ValidatedOptions[Implementation]? = "2.0" then
            ClickHouseAdbcConnection(server, port, database, ValidatedOptions[HighPrecision]?, ValidatedOptions[SSLMode]?)
        else
            OdbcDatasourceForSelectedDatabase;



// Data Source Kind description


ClickHouse = [
    // Set the TestConnection handler to enable gateway support.
    // The TestConnection handler will invoke your data source function to
    // validate the credentials the user has provider. Ideally, this is not
    // an expensive operation to perform. By default, the dataSourcePath value
    // will be a json string containing the required parameters of your data
    // source function. These should be parsed and parsed as individual parameters
    // to the specified data source function.
    // Optional parameters (including Implementation) are excluded from the data-source path,
    // so the handler cannot know which transport the source uses. ValidateConnection probes
    // Flight SQL first and falls back to the legacy transport, so credentials are validated
    // on whichever protocol the endpoint actually speaks.
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            server = json[server],
            port = json[port],
            database = try json[database] otherwise null
        in
            {"ClickHouse.ValidateConnection", server, port, database},
    // Set supported types of authentication
    Authentication = [
        //Windows = [],
        UsernamePassword = []
    ],
    SupportsEncryption = true,
    Label = Extension.LoadString("DataSourceLabel")
];

// Credential validation for TestConnection (gateway/service refresh). The data-source path
// carries only server+port, so the transport is probed: an authenticated Flight SQL metadata
// call first; on a TRANSPORT-level failure the legacy implementation is tried — that fallback
// is deliberate and required, because one validation function serves both implementations
// (an ODBC source's port does not speak Flight, and an ODBC-only host has no ADBC driver, yet
// both must still validate). Failures that prove the endpoint itself was reached are surfaced
// immediately instead of falling back: authentication failures (credential rejected),
// authorization failures (credential accepted, rights missing), and TLS/certificate failures
// (retrying over the legacy transport cannot cure the trust problem and would mask it). When
// both probes fail, both errors are reported so neither transport masks the other.
[DataSource.Kind = "ClickHouse"]
shared ClickHouse.ValidateConnection = (server as text, port as number, optional database as text) as number =>
    let
        // Structured detection first: the host attaches the driver's ADBC status code to the
        // error Detail (13 = UNAUTHENTICATED, 14 = UNAUTHORIZED). Message matching remains
        // only for the classes the codes cannot discriminate: TLS/certificate failures carry
        // the same IO status (10) as an unreachable endpoint, and ClickHouse authorization
        // errors arrive as server-side text.
        IsEndpointProof = (e as record) as logical =>
            let
                adbcStatus = try e[Detail][AdbcError][AdbcStatus] otherwise null,
                msg = Text.Lower(e[Message]? ?? "")
            in adbcStatus = 13 or adbcStatus = 14
                or Text.Contains(msg, "unauthenticated")
                or Text.Contains(msg, "authentication failed")
                or Text.Contains(msg, "not enough privileges")
                or Text.Contains(msg, "access_denied")
                or Text.Contains(msg, "certificate")
                or Text.Contains(msg, "tls handshake"),
        flight = try Table.RowCount(ClickHouseAdbcConnection(server, port, database, null)),
        result =
            if not flight[HasError] then flight[Value]
            else if IsEndpointProof(flight[Error]) then error flight[Error]
            else
                let legacy = try Table.RowCount(ClickHouse.Database(server, port, database, null))
                in
                    if not legacy[HasError] then legacy[Value]
                    else error Error.Record(
                        legacy[Error][Reason]? ?? "DataSource.Error",
                        (legacy[Error][Message]? ?? "")
                            & " (Arrow Flight SQL attempt also failed: " & (flight[Error][Message]? ?? "") & ")",
                        legacy[Error][Detail]?)
    in
        result;

// Data Source UI publishing description
ClickHouse.Publish = [
    Beta = true,
    Category = "Database",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://clickhouse.com",
    SupportsDirectQuery = Config_EnableDirectQuery,
     SourceImage = ClickHouse.Icons,
     SourceTypeImage = ClickHouse.Icons
];

ClickHouse.Icons = [
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


ConvertOptionsStringToRecord = (optionsString as text, ValidOptionsMap as table) as record =>
        let
            // Split the options string into rows (drop blanks from trailing/double ';')
            optionRows = List.Select(Text.Split(optionsString, ";"), each Text.Trim(_) <> ""),

            // Split each row into key-value pairs, trimming whitespace so "a=1; b=2" works
            // (otherwise the key becomes " b" and fails validation).
            keyValuePairs = List.Transform(optionRows, each List.Transform(Text.Split(_, "="), Text.Trim)),

            flattenedList = List.Combine(keyValuePairs),

            extractedOptionsFromMap = List.Select(ValidOptionsMap[Name], each List.Contains(keyValuePairs, {_, _})),
            // Identify keys from optionsString that don't exist in ValidOptionsMap
        invalidKeys = List.Difference(List.Transform(keyValuePairs, each Text.Clean(Text.Trim(_{0}))), ValidOptionsMap[Name]),
        extractedOptionsRecord = Record.FromList(List.Alternate(flattenedList, 1, 1), List.Alternate(flattenedList, 1, 1, 1)),
        

        optionsToTransform = Table.SelectRows(ValidOptionsMap, each (not Type.Is([Type],type nullable text) and not Type.Is([Type],type text))),
        typeTransformations = Table.AddColumn(optionsToTransform , "Value", each 
                                                                if (Type.Is([Type], type nullable number)) or (Type.Is([Type], type number)) 
                                                                    then { [Name], Number.FromText}
                                                                else if (Type.Is([Type], type nullable logical)) or (Type.Is([Type], type logical)) 
                                                                    then { [Name], Logical.FromText}
                                                                else null),


        convertedRecord = Record.TransformFields(extractedOptionsRecord,Table.Column(typeTransformations,"Value"),MissingField.Ignore),
             optionsRecordStr = Text.Combine(
        List.Transform(Record.FieldNames(convertedRecord), each Text.From(_ & " = " & Text.From(Record.Field(convertedRecord, _)))),
        ", ")
        in
                if not List.IsEmpty(invalidKeys) then
                error Error.Record("Expression.Error", 
                    Text.Format(
                    "'#{0}' unvalid options were provided. Valid options are: '#{1}'",
                    {Text.Combine(invalidKeys, ", "), Text.Combine(ValidOptionsMap[Name], ", ")}
                )
                   
                )
        
        else
            convertedRecord;


// build settings based on configuration variables
BuildOdbcConfig = () as record =>
    let
        Merge = (previous as record, optional caps as record, optional funcs as record, optional getInfo as record) as record =>
            let
                newCaps = if (caps <> null) then previous[SqlCapabilities] & caps else previous[SqlCapabilities],
                newFuncs = if (funcs <> null) then previous[SQLGetFunctions] & funcs else previous[SQLGetFunctions],
                newGetInfo = if (getInfo <> null) then previous[SQLGetInfo] & getInfo else previous[SQLGetInfo]
            in
                [SqlCapabilities = newCaps, SQLGetFunctions = newFuncs, SQLGetInfo = newGetInfo],
        defaultConfig = [
            SqlCapabilities = [],
            SQLGetFunctions = [],
            SQLGetInfo = []
        ],
        withParams =
            if (Config_UseParameterBindings = false) then
                let
                    caps = [
                        SupportsNumericLiterals = true,
                        SupportsStringLiterals = true,
                        SupportsOdbcDateLiterals = true,
                        SupportsOdbcTimeLiterals = true,
                        SupportsOdbcTimestampLiterals = true
                    ],
                    funcs = [
                        SQL_API_SQLBINDPARAMETER = false
                    ]
                in
                    Merge(defaultConfig, caps, funcs)
            else
                defaultConfig,
        withEscape =
            if (Config_StringLiterateEscapeCharacters <> null) then
                let
                    caps = [
                        StringLiteralEscapeCharacters = Config_StringLiterateEscapeCharacters
                    ]
                in
                    Merge(withParams, caps)
            else
                withParams,
        withLimitClauseKind = let caps = [
            LimitClauseKind = Config_LimitClauseKind
        ] in Merge(withEscape, caps),
        withCastOrConvert =
            if (Config_UseCastInsteadOfConvert <> null) then
                let
                    value =
                        if (Config_UseCastInsteadOfConvert = true) then
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CAST]
                        else
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CONVERT],
                    getInfo = [
                        SQL_CONVERT_FUNCTIONS = value
                    ]
                in
                    Merge(withLimitClauseKind, null, null, getInfo)
            else
                withLimitClauseKind,
        withSqlConformance =
            if (Config_SqlConformance <> null) then
                let
                    getInfo = [
                        SQL_SQL_CONFORMANCE = Config_SqlConformance
                    ]
                in
                    Merge(withCastOrConvert, null, null, getInfo)
            else
                withCastOrConvert
    in
        withSqlConformance;

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

// OdbcConstants contains numeric constants from the ODBC header files, and a
// helper function to create bitfield values.
ODBC = Extension.LoadFunction("OdbcConstants.pqm");

/****************************************
 * ADBC / Arrow Flight SQL implementation ("2.0")
 *
 * ClickHouse does NOT implement CommandGetXdbcTypeInfo, so Power BI's automatic
 * (Adbc.DataSource) type resolution fails for every column ("Unable to understand the
 * type for column"). Instead we use Adbc.Connection and derive each table's column types
 * ourselves from `DESCRIBE TABLE`, mapping ClickHouse type strings to M types. Query
 * folding is provided by SqlView.Generator + ClickHouseSqlGenerator.pqm.
 ****************************************/

// Loads a .pqm module that evaluates to a value (kept for the later folding work).
Extension.LoadExpression = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Adbc.Connection is provided by the host mashup engine. Resolve defensively so the
// connector still loads (and the ODBC path keeps working) where it is unavailable.
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

// Standard navigation-table wrapper.
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
            #"adbc.flight.sql.rpc.call_header.x-clickhouse-client-name" = "PowerBi/" & ConnectorVersion & "-adbc"
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
