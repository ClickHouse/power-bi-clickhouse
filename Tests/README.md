# Connector test suites (PQTest)

Automated tests for the ClickHouse Power BI connector, following the structure Microsoft uses
for its certified connectors: each test is a `.query.pq` (an M expression executed against a
live ClickHouse) paired with a `.query.pqout` (expected-result snapshot). Tests are run with
**PQTest** from the Power Query SDK — on Windows, either from the VS Code Test Explorer
(Power Query SDK extension) or the `pqtest.exe` CLI.

## Layout

```
Tests/
  Fixtures/seed.sql        deterministic fixture tables (database `pqtest`)
  ParameterQueries/        connection bootstraps (one per implementation)
  Settings/                one .testsettings.json per suite = what Test Explorer discovers
  TestSuites/
    Sanity/                connect, navigation, load, column types
    Folding/               filter / group-by / sort / distinct fold correctly
    KnownIssues/           regression guards for bugs fixed during development
    Functions/             function coverage (aggregates, dates, text)
    Comparison/            ODBC vs ADBC same-results checks
```

## Setup

1. **Seed the server:** run `Fixtures/seed.sql` against your ClickHouse
   (`clickhouse-client < seed.sql`). All data is deterministic — snapshots are stable.
2. **Point the bootstraps at your server:** edit `Server`/`Port` at the top of
   `ParameterQueries/*.parameterquery.pq` (ADBC = Arrow Flight port; ODBC = HTTP port)
   and in `TestSuites/Comparison/AdbcOdbcSameResults.query.pq`.
3. **Build the connector** (`ClickHouse.mez`) and configure the SDK extension's extension path.
4. **Set credentials** once via the SDK's *Power Query: Set Credential* command
   (Basic auth for the ClickHouse data source).

## Machine setup for the runner script

`run-tests.sh` drives PQTest on a Windows machine over SSH. Copy
`run-tests.env.example` to `run-tests.env` (not committed) and fill in your SSH
destination, the Windows paths, and the ClickHouse host address as seen from Windows.

## Running

- **VS Code:** open this connector folder, then Test Explorer lists one node per file in
  `Settings/`. Run a suite; PQTest executes every `.query.pq` in the suite's folder.
- **First run:** `FailOnMissingOutputFile` is `false`, so missing `.pqout` snapshots are
  generated. Review them against the expected values below, commit them, then flip the flag
  to `true` to make the suites strict.

## Expected values (for reviewing generated snapshots)

| Test | Field | Expected |
|---|---|---|
| Sanity/LoadTable | rows per table | numbers 5, dates 3, text 5, division 3, big_ids 4, events 100 |
| Folding/FilterEquals | Rows / Rid | 1 / 4 |
| Folding/FilterRangeGroupBy | Groups / FirstName / FirstTotal / FirstCnt | 10 / name_0 / 43.75 / 5 |
| Folding/SortFirstN | Ids | 99,98,97 |
| Folding/DistinctCount | DistinctNames / AllRows | 10 / 100 |
| KnownIssues/DecimalDivision | Row1RatioRounded / Row2Ratio / Row3Ratio | 0.769 / 4 / 0 |
| KnownIssues/BigIntEquality | Rows / Label | 1 / two_pow_53_plus_1 |
| KnownIssues/NestedAggregation | Total | 618.75 |
| Functions/Aggregates | SumI32 / AvgF64 / SumDec / CountAll | 100000 / 0.7 / -11302.25 / 5 |
| Functions/TextFunctions | Upper / Len / Pos / Starts | HELLO WORLD / 11 / 6 / true |
| Comparison/AdbcOdbcSameResults | all fields | true |
| Folding/MultiValueFilter | Buckets / First / GrandTotal | 4 / high / 93.12 |
| Folding/MinMaxDatesText | MinDate / MaxDate / MaxText | 2020-01-01 / 2026-12-31 / a-b-c |
| Folding/AverageTypes | AvgEventsId / AvgDecimal | 49.5 / -2260.45 |
| Folding/Arithmetic | Plus / Minus / Times | 101000 / 99000 / 7 |
| Folding/GroupDistinctCount | Groups / FirstDays / TotalDays | 10 / 3 / 30 |
| Folding/ApproxDistinct | Groups / FirstDays | 10 / 3 |
| Functions/NumericFrom | DF / NF | 100000 / 999.99 |
| Functions/ValueCompare | Less / Equal / Greater | -1 / 0 / 1 |
| Functions/DateCoverage | leap-day parts, period starts, add* family | 2024-02-29 row; AddY/AddM clamp to 2025-02-28 |
| Functions/TextFolding | Upper/Lower/Len/Left/Right/Replace/PositionOf | HELLO WORLD / … / PosFound 6 / PosNotFound -1 |
| Functions/TextUnicode | PosAccent / PosEmoji / LenAccent / LenEmoji / StartAccent / EndAccent / LowerAccent / UpperAccent | 1 / 2 / 2 / 3 / ÉX / café / éxample café / ÉX |
| Folding/DistinctCountListShape | Groups / FirstDays | 10 / 3 |
| Functions/SumPrecisionDecimal | SumDecimalPrecision | 3.5 (folds as SUM(cast(f64 as Decimal(38, 10)))) |
| Functions/ValueAsFold | VA | 100000 (pure passthrough) |
| Functions/PrecisionArithmetic | Op / DefaultDiv / DoubleDiv / DecimalDiv / DoubleFrom | 0.76923076923076916 ×3 / 0.7692307692 / 0.76923076923076916 |
| Functions/NativeQuery | FirstName / FirstTotal / Rows / UniqWithSettings | name_0 / 1.25 / 2 / 10 |
| Folding/EscapedLiterals | EqualityRows / Rid / ContainsRows | 1 / 5 / 1 |
| Functions/TextPredicates | ContainsRows / StartsRows / EndsRows | 1 / 1 / 1 |
| KnownIssues/NullableColumns | SumV / SumN / Rows / BigN | 4 / 60 / 4 / 2 |
| KnownIssues/NullSemantics | CountWithNulls / DistinctWithNull / TableDistinct / MultiColDistinct / MemberWithNull / MemberOnlyNull / MemberPlain / MemberEmpty | 4 / 4 / 4 / 4 / 2 / 1 / 2 / 0 |
| KnownIssues/OuterJoinNulls | Rows / NullA | 5 / 2 |
| KnownIssues/ExoticTypes | Cols / U64 / U64Filter / En / Ip / Arr | rid,u64,en,ip,arr,str / 18446744073709551615 / 1 / 2 / 16909060 / 1,2,3 |
| KnownIssues/PlainDateTime | Rows / DtEpoch / Dt64Text | 2 / 1709209845 / 2024-02-29 12:30:45 |

## Connection validation tests

`run-tests.sh` also runs `docker/run-connection-tests.ps1` per target — four TestConnection
scenarios asserting the probe routing: Flight success, immediate credential-failure
propagation (reported as a credential error, no fallback masking), legacy fallback for a
non-Flight (HTTP) port, and a dead port reporting BOTH transport errors.

## What the suites guard

- **KnownIssues/DecimalDivision** — decimal ratios must not collapse to integers
  (bare `DECIMAL` in ClickHouse is `Decimal(10, 0)`; the generator casts to `Decimal(38, 10)`).
- **KnownIssues/BigIntEquality** — 64-bit values above 2^53 must round-trip exactly
  (guards against DOUBLE coercion in folded comparisons).
- **KnownIssues/NestedAggregation** — aggregation over an aggregated subquery (the shape
  report visuals generate) must not fail on alias resolution.
- **KnownIssues/ExoticTypes** — the type contract at the edges: UInt64 above 2^63-1 loads
  exactly and folds exact equality (DECIMAL mapping + CAST literal — a BIGINT declaration made
  the engine round filter literals through DOUBLE and silently return 0 rows); Enum/IPv4
  surface as numeric representations; Arrays load as M lists; FixedString/UUID columns (which
  crash the ADBC reader) are excluded from the table instead of failing the load.
- **KnownIssues/NullSemantics** — folded counts, distinct counts, and membership filters over
  nullable columns must match M's null semantics (M counts nulls and treats null as a distinct
  value; plain SQL aggregates and `IN` skip them).
- **Functions/TextUnicode** — text folding must count characters, not bytes: multi-byte
  UTF-8 content folds via positionUTF8/lengthUTF8/leftUTF8/rightUTF8/lowerUTF8/upperUTF8
  (byte-based position('éx', 'x') returns 2 where M returns 1). lowerUTF8/upperUTF8 need a
  server built with ICU (all stock releases); without it the engine falls back to local
  evaluation with correct values.
- **Functions/PrecisionArithmetic** — explicit M precision requests must be honored in folded
  arithmetic: ClickHouse Decimal division keeps the dividend's scale (1 / 1.3 → 0.769), so
  `Precision.Double` folds with DOUBLE casts (matching local M), `Precision.Decimal` widens the
  dividend to `Decimal(38, 10)`, and `Double.From` over a Decimal column is a real conversion.
- **KnownIssues/OuterJoinNulls** — outer merges must carry null for unmatched rows. With
  ClickHouse's default `join_use_nulls = 0` a folded outer join fills type defaults (0, ''),
  so outer-join folding is disabled until the Arrow Flight SQL interface supports
  per-connection settings (then it can be re-enabled with `join_use_nulls = 1` pinned);
  this fails if it is ever re-enabled without null preservation.
- **Folding/** — results are validated end to end; to additionally inspect the generated SQL,
  check the ClickHouse query log (`system.query_log`, `interface = 10`) or the server trace log.

## Runner notes (learned the hard way)

- Run `compare` from the `Tests/Settings` directory — relative paths in the settings JSON
  resolve against the current working directory, not the settings file.
- Every `.query.pq` must be a `(source) => ...` function when run via a settings file with a
  parameter query — standalone `let` queries fail with "cannot convert Record to Function".
- Do NOT set `DiagnosticsFolderPath` in the settings files: with SdkTools 2.146.x it activates
  a diagnostics path whose service fails to initialize, and every ADBC evaluation then dies
  with a bare "Object reference not set" error (thrown while constructing the query event).
  Use PQTest's `-l`/`-trx` flags instead when traces are needed.
- If a test ever ran while broken (bad server address, missing credential), delete its stale
  `.pqout` before rerunning — snapshot generation may have captured the old error text, and a
  later "Passed" against such a snapshot is meaningless. Always eyeball generated snapshots
  against the expected-values table above.
- The ClickHouse server must implement/accept `CloseSession`; the ADBC host closes sessions on
  connection cleanup and the evaluation fails if that call errors.

## Proving folding (not just values)

Passing values do NOT prove a step folded — on small fixtures a silently-unfolded step
computes the same answer locally. PQTest's `--failOnFoldingFailure` does not detect this
for record-returning tests. The reliable proof is server-side: after a suite run, check
`system.query_log` (Flight = `interface 10`) for the expected SQL fragments, e.g.
`uniqExact("d")`, `uniq("d")`, `"id" in (`, `startsWith`, `endsWith`, `position(`,
`case when`. All fragments listed here were verified present after the current suites.

Known folding quirk (backlog): integer+integer computed columns fold with engine-injected
`cast(... as DOUBLE)` on both operands (float arithmetic folds clean); values above 2^53
in such computed columns would lose precision.
