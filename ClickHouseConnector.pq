// This connector provides a sample Direct Query enabled connector
// based on an ODBC driver. It is meant as a template for other
// ODBC based connectors that require similar functionality.
//
[Version = "0.1.4"]
section ClickHouse;

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
        Documentation.FieldDescription = "Port used by ClickHouse",
        Documentation.SampleValues = {443, 8123, 8443}  
    ]),
    optional database as (type text meta [
        Documentation.FieldCaption = "Database",
        Documentation.FieldDescription = "Name of ClickHouse database",
        Documentation.SampleValues = {"default"}  
    ]),    
    optional options as (type text meta [
        Documentation.FieldCaption = "Options",
        Documentation.FieldDescription = "Additional connection string options separated by semicolon",
        Documentation.SampleValues = {"Timeout=600;UseUnicode=true","UseUnicode=true"}
    ]))
    as table meta [
        Documentation.Name = "ClickHouse",
        Documentation.LongDescription = "ClickHouse ODBC connector for Power Query",
         Documentation.Examples = {[
            Description = "Returns a navigation table with list of play.clickhouse.com tables, that can be folded",
            Code = "ClickHouse.Database(""https://play.clickhouse.com"")"
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
                    "Certificate verification method (used by TLS/SSL connections, ignored in Windows), one of: allow, prefer, require, use allow to enable SSL_VERIFY_PEER TLS/SSL certificate verification mode, SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT is used otherwise",
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
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            server = json[server],
            port = json[port]
        in
            {"ClickHouse.Database", server, port},
    // Set supported types of authentication
    Authentication = [
        //Windows = [],
        UsernamePassword = []
    ],
    SupportsEncryption = true,
    Label = Extension.LoadString("DataSourceLabel")
];

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
            // Split the options string into rows
            optionRows = Text.Split(optionsString, ";"),

            // Split each row into key-value pairs
            keyValuePairs = List.Transform(optionRows, each Text.Split(_, "=")),

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