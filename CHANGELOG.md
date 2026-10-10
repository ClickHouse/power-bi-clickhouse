# ClickHouse PowerBI Connector changelog

## Unreleased

### New features

- ClickHouse Cloud SSO authentication: users sign in through ClickHouse Cloud (OAuth 2.0 Authorization Code + PKCE),
  the connector exchanges the OAuth token for a ClickHouse JWT scoped to the service hostname, and the JWT is passed
  to the ODBC driver as `AccessToken`. Requires an ODBC driver version that supports `AccessToken`.
  The short-lived ClickHouse JWT is renewed silently by re-exchanging the OAuth token for as long as it is valid;
  afterwards the user is asked to sign in again (or, once the client allows the Refresh Token grant, the OAuth token
  is renewed silently as well). Sign-in always asks for credentials so a different account can be chosen.
  Currently configured against the ClickHouse Cloud **dev** environment endpoints.
- Authentication failures reported by the driver (SQLSTATE `28000`) now prompt the user to sign in again.

## 0.1.4-beta, 2024-01-14

### Bug fixes

- Fix casting issue [#9](https://github.com/ClickHouse/power-bi-clickhouse/issues/9) by overwrite SQL_CONVERT_FUNCTIONS
  to let Power BI know that ClickHouse uses CAST and not CONVERT.

## 0.1.3-beta, 2024-01-02

### Bug fixes

- Fix ODBC options parsing. [#11](https://github.com/ClickHouse/power-bi-clickhouse/issues/11)
- Rename output mez file

## 0.1.2-beta, 2023-12-07

### Bug fixes

- Fix test connection handler gateway
  usage. [#5](https://github.com/ClickHouse/power-bi-clickhouse/issues/5) + [#3](https://github.com/ClickHouse/power-bi-clickhouse/issues/3)
- Rename connector

## 0.1.1-beta, 2023-09-20

### Bug fixes

- Fix data types mapping issue. [#1](https://github.com/ClickHouse/power-bi-clickhouse/issues/1)

## 0.1.0-beta, 2023-09-12

### Bug fixes

- Fixed a core issue in the build process to make it compatible with non-SSL
  instances. [#2](https://github.com/ClickHouse/power-bi-clickhouse/issues/2)

## 0.0.1-beta, 2023-08-22

### Improvements

- The initial version of the Power BI <> ClickHouse connector. Support direct query mode
