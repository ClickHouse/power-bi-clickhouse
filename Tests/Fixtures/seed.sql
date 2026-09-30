-- Deterministic fixtures for the connector test suites (PQTest).
-- Run against any ClickHouse:  clickhouse-client < seed.sql   (or paste via HTTP).
-- All data is fixed — no now()/random — so result snapshots are stable.

CREATE DATABASE IF NOT EXISTS pqtest;

DROP TABLE IF EXISTS pqtest.numbers;
CREATE TABLE pqtest.numbers
(
    rid   UInt8,
    i8    Int8,
    i16   Int16,
    i32   Int32,
    i64   Int64,
    u64   UInt64,
    f32   Float32,
    f64   Float64,
    dec92   Decimal(9, 2),
    dec3810 Decimal(38, 10)
)
ENGINE = MergeTree ORDER BY rid;

INSERT INTO pqtest.numbers VALUES
    (1, -128,  -32768, -2147483648, -9223372036854775808, 0,                    -1.5,  -2.25, -12345.67, -1.0000000001),
    (2,  0,     0,      0,           0,                    0,                     0,     0,     0,         0),
    (3,  1,     1,      1,           1,                    1,                     0.5,   0.25,  1.01,      1.0000000001),
    (4,  100,   1000,   100000,      10000000000,          10000000000,           3.25,  3.5,   999.99,    123.4567890123),
    (5,  127,   32767,  2147483647,  9223372036854775807,  18446744073709551615,  2,     2,     42.42,     42.0000000042);

DROP TABLE IF EXISTS pqtest.dates;
CREATE TABLE pqtest.dates
(
    rid  UInt8,
    d    Date,
    dt64 DateTime64(3, 'UTC')
)
ENGINE = MergeTree ORDER BY rid;

INSERT INTO pqtest.dates VALUES
    (1, '2020-01-01', '2020-01-01 00:00:00.000'),
    (2, '2024-02-29', '2024-02-29 12:30:45.123'),
    (3, '2026-12-31', '2026-12-31 23:59:59.999');

DROP TABLE IF EXISTS pqtest.text;
CREATE TABLE pqtest.text
(
    rid UInt8,
    s   String,
    lc  LowCardinality(String),
    ns  Nullable(String)
)
ENGINE = MergeTree ORDER BY rid;

INSERT INTO pqtest.text VALUES
    (1, 'Hello World',    'alpha', 'x'),
    (2, 'a-b-c',          'beta',  NULL),
    (3, '',               'alpha', 'longer text value'),
    (4, 'CaseSensitive',  'gamma', 'x');

DROP TABLE IF EXISTS pqtest.division;
CREATE TABLE pqtest.division
(
    rid UInt8,
    a Decimal(9, 3),
    b Decimal(9, 3)
)
ENGINE = MergeTree ORDER BY rid;

INSERT INTO pqtest.division VALUES
    (1, 1, 1.3),
    (2, 2, 0.5),
    (3, 0, 1);

DROP TABLE IF EXISTS pqtest.big_ids;
CREATE TABLE pqtest.big_ids
(
    id UInt64,
    label String
)
ENGINE = MergeTree ORDER BY id;

INSERT INTO pqtest.big_ids VALUES
    (1001,                'small'),
    (9007199254740992,    'two_pow_53'),
    (9007199254740993,    'two_pow_53_plus_1'),
    (9007199254740995,    'two_pow_53_plus_3');

DROP TABLE IF EXISTS pqtest.events;
CREATE TABLE pqtest.events
(
    id   Int64,
    name String,
    val  Float64,
    d    Date
)
ENGINE = MergeTree ORDER BY id;

INSERT INTO pqtest.events
SELECT
    number,
    concat('name_', toString(number % 10)),
    number / 8,
    toDate('2026-01-01') + (number % 30)
FROM numbers(100);

DROP TABLE IF EXISTS pqtest.nullable;
CREATE TABLE pqtest.nullable
(
    rid UInt8,
    v Nullable(Float64),
    n Nullable(Int64),
    s Nullable(String)
)
ENGINE = MergeTree ORDER BY rid;

INSERT INTO pqtest.nullable VALUES
    (1, 1.5,  10,   'a'),
    (2, NULL, NULL, NULL),
    (3, 2.5,  20,   'b'),
    (4, NULL, 30,   NULL);

DROP TABLE IF EXISTS pqtest.datetimes;
CREATE TABLE pqtest.datetimes
(
    rid UInt8,
    dt   DateTime('UTC'),
    dt64 DateTime64(3, 'UTC')
)
ENGINE = MergeTree ORDER BY rid;

INSERT INTO pqtest.datetimes VALUES
    (1, '2024-02-29 12:30:45', '2024-02-29 12:30:45.123'),
    (2, '2020-01-01 00:00:00', '2020-01-01 00:00:00.000');

INSERT INTO pqtest.text VALUES (5, 'O''Brien \\ C:\\dir\\name', 'delta', NULL);

DROP TABLE IF EXISTS pqtest.unicode;
CREATE TABLE pqtest.unicode
(
    rid UInt8,
    s   String
)
ENGINE = MergeTree ORDER BY rid;

-- Multi-byte UTF-8 content: é (2 bytes), ß (2 bytes), 🎉 (4 bytes). Guards character-aware
-- (not byte-aware) folding of position/length/left/right/lower/upper.
INSERT INTO pqtest.unicode VALUES
    (1, 'éx'),
    (2, 'ÉXAMPLE café'),
    (3, 'a🎉x');
