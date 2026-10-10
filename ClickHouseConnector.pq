// This connector provides a sample Direct Query enabled connector
// based on an ODBC driver. It is meant as a template for other
// ODBC based connectors that require similar functionality.
//
[Version = "0.1.5"]
section ClickHouse;
ConnectorVersion = "0.1.5";

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
Config_UseParameterBindings = true;
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

/****************************
 * ClickHouse Cloud SSO Configuration
 ****************************/
// ClickHouse Cloud SSO is an OAuth 2.0 Authorization Code + PKCE login against the ClickHouse Cloud
// Auth0 tenant, followed by an exchange of the OAuth access token for a ClickHouse JWT scoped to the
// service hostname (see ExchangeForClickHouseJwt). The OAuth client is confidential, so its secret is
// embedded below; the .mez file is a zip readable by anyone, so the secret only protects the login
// flow (PKCE is still required) and must not be treated as a trust boundary.
// The application's Allowed Callback URLs must include OAuth_RedirectUri. Silent token refresh needs
// the Refresh Token grant enabled on the client; without it users are asked to sign in again on expiry.
// These are the DEV environment endpoints; production is a one-record swap.
CloudSso = [
    AuthorizeUrl = "TODO: FILL IN",
    TokenUrl = "TODO: FILL IN ",
    TokenExchangeUrl = "TODO: FILL IN",
    // Auth0 connection that routes the login to ClickHouse Cloud SSO; required on /authorize.
    Connection = "TODO: FILL IN",
    ClientId = "TODO: FILL IN",
    ClientSecret = "TODO: FILL IN",
    // access:services is required by the token exchange; offline_access requests a refresh token.
    Scope = "TODO: FILL IN"
];
OAuth_RedirectUri = "https://oauth.powerbi.com/views/oauthredirect.html";
OAuth_WindowWidth = 720;
OAuth_WindowHeight = 1024;

// true, false
[DataSource.Kind = "ClickHouse", Publish = "ClickHouse.Publish"]
shared ClickHouse.Database = Value.ReplaceType(DatabaseCoreImplementation, DatabaseType);



// Documanting the function
DatabaseType = type function (
    server as (type text meta [
        Documentation.FieldCaption = "Host",
        Documentation.FieldDescription = "Name of ClickHouse Host (name only, without prefixes",
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
    optional options as (type record meta [
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



DatabaseCoreImplementation = (server as text, port as number, optional database as text, optional options as record) =>
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
                    "HugeIntAsString",
                    type nullable text,
                    "Report integer column types that may underflow or overflow 64-bit signed integer (SQL_BIGINT) as a String/SQL_VARCHAR",
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

        parsedOptions = if (Type.Is(Value.Type(options), type record))
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
            ClientName = "PowerBi/" & ConnectorVersion,
            SQLCompatibilitySettings = 1,
            
            // These fields come from the options record, so they might be null.
            // A later step will strip all null values from the connection string.
            #"Timeout" = ValidatedOptions[Timeout]?,
            #"VerifyConnectionEarly" = ValidatedOptions[VerifyConnectionEarly]?,
            #"SSLMode" = ValidatedOptions[SSLMode]?,
            #"HugeIntAsString" = ValidatedOptions[HugeIntAsString]?


        ],
        //
        // Handle credentials
        // Credentials are not persisted with the query and are set through a separate
        // record field - CredentialConnectionString. For OAuth (ClickHouse Cloud SSO), the stored
        // access_token is already the ClickHouse JWT obtained by token exchange in FinishLogin/Refresh;
        // it is passed to the driver, which sends it as "Authorization: Bearer <token>".
        // The JWT is short-lived; Power Query calls Refresh before it expires (see ExchangeForClickHouseJwt).
        //
        Credential = Extension.CurrentCredential(),
        CredentialConnectionString =
            if Credential[AuthenticationKind]? = "UsernamePassword" then
                [UID = Credential[Username], PWD = Credential[Password]]
            else if Credential[AuthenticationKind]? = "OAuth" then
                [AccessToken = Credential[access_token]]
            else
                error Error.Record(
                    "Expression.Error", "Unhandled authentication kind: " & Text.From(Credential[AuthenticationKind]?)
                ),
          
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
        OdbcDatasource = try Odbc.DataSource(
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
                SQLGetTypeInfo = SQLGetTypeInfo,
                // Converts driver authentication failures into credential errors
                OnError = OnOdbcError
            ]
        )
        catch (e)=>
            // check if the error is related to missing driver, if so add a link for installation,
            // else raise the error as is (so credential errors still trigger a sign-in prompt)
            if Text.Contains(e[Message], "doesn't correspond to an installed ODBC driver") then
                error Error.Record(
                    e[Reason],
                    e[Message] & " Please visit the installation guide: https://github.com/ClickHouse/clickhouse-odbc.",
                    e[Detail]
                )
            else
                error e,
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
            port = json[port],
            database = try json[database] otherwise null,
            options = try json[options] otherwise null

        in
            {"ClickHouse.Database", server, port, database, options},
    // Set supported types of authentication
    Authentication = [
        //Windows = [],
        UsernamePassword = [],
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Label = Extension.LoadString("AuthenticationLabelOAuth")
        ]
    ],
    SupportsEncryption = true,
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
ClickHouse.Publish = [
    Beta = false,
    Category = "Database",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://clickhouse.com/docs/en/integrations/powerbi",
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

/****************************
 * ClickHouse Cloud SSO implementation (OAuth + token exchange)
 ****************************/
// Authorization Code flow with PKCE. Power Query opens LoginUri in a browser window,
// waits for a redirect to CallbackUri and passes it to FinishLogin together with Context.
// resourceUrl is the data source path: a JSON string with the same fields TestConnection parses.
StartLogin = (resourceUrl, state, display) =>
    let
        hostname = HostnameFromResourceUrl(resourceUrl),
        // 64 chars from [0-9a-f], within the 43-128 range required by RFC 7636
        codeVerifier = Text.Remove(Text.NewGuid() & Text.NewGuid(), "-"),
        codeChallenge = Base64UrlEncode(
            Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(codeVerifier, TextEncoding.Ascii))
        ),
        authorizeUrl = CloudSso[AuthorizeUrl] & "?" & Uri.BuildQueryString([
            connection = CloudSso[Connection],
            // Always ask for credentials instead of silently reusing the browser's SSO session; Auth0
            // forwards prompt=login to the upstream ClickHouse IdP, so "Sign in as different user" works.
            prompt = "login",
            response_type = "code",
            client_id = CloudSso[ClientId],
            redirect_uri = OAuth_RedirectUri,
            scope = CloudSso[Scope],
            state = state,
            code_challenge = codeChallenge,
            code_challenge_method = "S256"
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = OAuth_RedirectUri,
            WindowHeight = OAuth_WindowHeight,
            WindowWidth = OAuth_WindowWidth,
            // FinishLogin does not receive resourceUrl, so the hostname travels with the verifier in Context.
            Context = Text.FromBinary(Json.FromValue([code_verifier = codeVerifier, hostname = hostname]))
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        ctx = Json.Document(context),
        parts = Uri.Parts(callbackUri)[Query]
    in
        if Record.HasFields(parts, {"error"}) then
            error Error.Record(parts[error], parts[error_description]?)
        else
            ExchangeForClickHouseJwt(
                TokenMethod([
                    grant_type = "authorization_code",
                    code = parts[code],
                    redirect_uri = OAuth_RedirectUri,
                    code_verifier = ctx[code_verifier]
                ]),
                ctx[hostname]
            );

// Called by Power Query when the stored ClickHouse JWT is about to expire. The refresh_token slot holds
// the RefreshState JSON written by ExchangeForClickHouseJwt (see there), so the handler can:
//   1. re-exchange the still-valid OAuth access token (24h) for a new ClickHouse JWT (5 min), and only
//   2. when that token has expired (401), renew it through the Refresh Token grant if Auth0 gave us one,
//   3. otherwise raise a credential error so Power BI asks the user to sign in again.
Refresh = (resourceUrl, refresh_token) =>
    let
        hostname = HostnameFromResourceUrl(resourceUrl),
        state = try Json.Document(refresh_token) otherwise null,
        oauthAccessToken = if state is record then state[oauth_access_token]? else null,
        // a non-JSON value is a bare Auth0 refresh token stored by an older build
        oauthRefreshToken = if state is record then state[oauth_refresh_token]? else refresh_token,
        reexchange =
            if oauthAccessToken = null then null
            else try ExchangeForClickHouseJwt([access_token = oauthAccessToken, refresh_token = oauthRefreshToken], hostname),
        reexchangeStatus = if reexchange <> null and reexchange[HasError] then (try reexchange[Error][Detail][Status] otherwise null) else null,
        oauthTokenExpired = reexchange = null or reexchangeStatus = 401,
        renewedOAuth = () =>
            let
                result = TokenMethod([grant_type = "refresh_token", refresh_token = oauthRefreshToken])
            in
                // Auth0 returns a new refresh token only when rotation is enabled; keep the old one otherwise
                if result[refresh_token]? = null then result & [refresh_token = oauthRefreshToken] else result
    in
        if not oauthTokenExpired then
            (if reexchange[HasError] then error reexchange[Error] else reexchange[Value])
        else if oauthRefreshToken <> null then
            ExchangeForClickHouseJwt(renewedOAuth(), hostname)
        else
            error Extension.CredentialError(
                Credential.AccessDenied, "Your ClickHouse Cloud session has expired, please sign in again."
            );

// No Logout handler: Power BI navigates its embedded browser to the returned URL and crashes the dialog if
// the server answers 4xx, and Auth0's /v2/logout returned 400 from Power BI's WebView2 session even though it
// returns 200 without cookies. prompt=login in StartLogin already forces a fresh credential prompt instead.

TokenMethod = (grant as record) as record =>
    let
        response = Web.Contents(
            CloudSso[TokenUrl],
            [
                Content = Text.ToBinary(Uri.BuildQueryString(
                    [client_id = CloudSso[ClientId], client_secret = CloudSso[ClientSecret]] & grant
                )),
                Headers = [#"Content-Type" = "application/x-www-form-urlencoded", Accept = "application/json"],
                ManualStatusHandling = {400, 401, 403}
            ]
        ),
        body = try Json.Document(response) otherwise [error = "invalid_response"],
        message = Text.From(body[error_description]? ?? body[error])
    in
        if body[error]? = null then
            body
        else if grant[grant_type] = "refresh_token" then
            error Extension.CredentialError(Credential.AccessDenied, "Session expired, please sign in again. " & message)
        else
            error Error.Record(body[error], message);

// Exchanges the OAuth access token for a ClickHouse JWT valid for the given service hostname and builds
// the credential record Power Query stores:
//   access_token  = the ClickHouse JWT handed to the ODBC driver (short-lived, currently 5 minutes)
//   expires_in    = seconds until that JWT expires, so Power Query calls Refresh in time
//   refresh_token = RefreshState JSON {"oauth_access_token": <24h OAuth token>, "oauth_refresh_token": <Auth0
//                   refresh token or null>}; refresh_token is the only value Power Query hands back to Refresh.
ExchangeForClickHouseJwt = (oauth as record, hostname as text) as record =>
    let
        request = () => Web.Contents(
            CloudSso[TokenExchangeUrl],
            [
                Content = Json.FromValue([hostname = hostname]),
                Headers = [
                    Authorization = "Bearer " & oauth[access_token],
                    #"Content-Type" = "application/json",
                    Accept = "application/json"
                ],
                ManualStatusHandling = {400, 401, 403, 404, 500, 502, 503, 504},
                // bypass Power Query's response cache so a retry really reaches the server
                IsRetry = true
            ]
        ),
        // The console API answered 500 for a token issued a second earlier while the same token worked
        // moments later from curl, so retry 5xx a few times with a short pause before giving up.
        response = RetryOnServerError(request, 3, #duration(0, 0, 0, 2)),
        status = Value.Metadata(response)[Response.Status]?,
        rawBody = try Text.FromBinary(response) otherwise "",
        parsed = try Json.Document(response) otherwise null,
        body = if parsed is record then parsed else [error = "invalid_response"],
        // The name of the JWT field in the response is not documented; accept the common variants.
        jwt = body[token]? ?? body[jwt]? ?? body[access_token]?,
        message = Text.From(
            body[error_description]? ?? body[message]? ?? body[error]? ?? ("HTTP " & Text.From(status ?? "?"))
        ),
        expiresIn = JwtSecondsToExpiry(jwt) ?? oauth[expires_in]?
    in
        if (status <> null and status >= 400) or jwt = null then
            error Error.Record(
                "TokenExchangeFailed",
                "Could not obtain a ClickHouse token for service '" & hostname & "'. " & message
                    & " (HTTP " & Text.From(status ?? "?") & "; OAuth token: " & DescribeOAuthToken(oauth[access_token])
                    & "; endpoint: " & CloudSso[TokenExchangeUrl] & ")"
                    // TODO: temporary debug aid, remove before release: exposes the raw OAuth access token
                    & " Response body: " & Text.Start(rawBody, 500)
                    & " OAuth access token: " & oauth[access_token],
                [Status = status, Hostname = hostname]
            )
        else
            [
                access_token = jwt,
                token_type = "Bearer",
                refresh_token = Text.FromBinary(Json.FromValue([
                    oauth_access_token = oauth[access_token],
                    oauth_refresh_token = oauth[refresh_token]?
                ]))
            ] & (if expiresIn = null then [] else [expires_in = expiresIn]);

// Describes the OAuth access token for diagnostics without revealing it: Auth0 issues an opaque token
// (useless to the console API) unless an audience applies, and a JWT otherwise. Shows aud/scope claims.
DescribeOAuthToken = (token as text) as text =>
    let
        segments = Text.Split(token, "."),
        payload = Json.Document(Base64UrlDecode(segments{1})),
        audList = if payload[aud]? is list then payload[aud] else {payload[aud]?},
        description =
            "JWT aud=[" & Text.Combine(List.Transform(audList, Text.From), ",") & "] scope=[" & Text.From(payload[scope]? ?? "") & "]"
    in
        if List.Count(segments) = 3 then
            (try description otherwise "JWT with undecodable payload")
        else
            "opaque, " & Text.From(Text.Length(token)) & " chars";

// Calls request() and, while the response status is 5xx and attempts remain, waits and calls it again.
RetryOnServerError = (request as function, attempts as number, delay as duration) as binary =>
    let
        response = request(),
        status = Value.Metadata(response)[Response.Status]?
    in
        if attempts > 1 and status <> null and status >= 500 then
            Function.InvokeAfter(() => @RetryOnServerError(request, attempts - 1, delay), delay)
        else
            response;

// The data source path is a JSON record of the data source function's required parameters. The token
// exchange accepts only the bare service hostname (a trailing ":", "/", a port, a scheme or surrounding
// whitespace all yield 403), so the Host field value is normalised here.
HostnameFromResourceUrl = (resourceUrl as text) as text =>
    let
        json = try Json.Document(resourceUrl) otherwise null,
        raw = if json is record and json[server]? <> null then Text.Trim(Text.From(json[server])) else null,
        withoutScheme = if raw <> null and Text.Contains(raw, "://") then Text.AfterDelimiter(raw, "://") else raw,
        withoutPath = if withoutScheme <> null then Text.BeforeDelimiter(withoutScheme, "/") else null,
        withoutPort = if withoutPath <> null then Text.BeforeDelimiter(withoutPath, ":") else null,
        hostname = if withoutPort <> null then Text.Lower(Text.Trim(withoutPort)) else null
    in
        if hostname <> null and hostname <> "" then
            hostname
        else
            error Error.Record(
                "Expression.Error", "Cannot determine the ClickHouse host from the data source path: " & resourceUrl
            );

// Seconds until the JWT's exp claim, less a safety margin, so Power Query refreshes the credential
// before ClickHouse starts rejecting it. Returns null if the token cannot be decoded.
JwtSecondsToExpiry = (jwt as nullable text) as nullable number =>
    let
        segments = Text.Split(jwt, "."),
        payload = Json.Document(Base64UrlDecode(segments{1})),
        nowSeconds = Duration.TotalSeconds(DateTimeZone.UtcNow() - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)),
        remaining = Number.RoundDown(payload[exp] - nowSeconds - 60)
    in
        try (if remaining > 0 then remaining else null) otherwise null;

Base64UrlEncode = (value as binary) as text =>
    Text.Replace(Text.Replace(Text.Remove(Binary.ToText(value, BinaryEncoding.Base64), "="), "+", "-"), "/", "_");

Base64UrlDecode = (value as text) as binary =>
    let
        standard = Text.Replace(Text.Replace(value, "-", "+"), "_", "/"),
        padded = standard & Text.Repeat("=", Number.Mod(4 - Number.Mod(Text.Length(standard), 4), 4))
    in
        Binary.FromText(padded, BinaryEncoding.Base64);

// The driver reports a rejected token with SQLSTATE 28000 (invalid authorization specification).
// Raising a credential error makes Power BI prompt the user to sign in again.
OnOdbcError = (errorRecord as record) =>
    let
        detail = errorRecord[Detail]?,
        odbcErrors = if detail is record then detail[OdbcErrors]? else null,
        odbcErrorList =
            if odbcErrors is table then Table.ToRecords(odbcErrors)
            else if odbcErrors is list then odbcErrors
            else {},
        hasCredentialError = List.AnyTrue(List.Transform(odbcErrorList, each (try _[SQLState] otherwise null) = "28000"))
    in
        if hasCredentialError then
            error Extension.CredentialError(Credential.AccessDenied, errorRecord[Message])
        else
            error errorRecord;


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
