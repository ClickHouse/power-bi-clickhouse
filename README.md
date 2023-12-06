<p align="center" style="font-size:300%">
<img src=".static/clickhouse.png" width="200px" align="center">
<img src=".static/powerbi.svg" width="200px" align="center">
<h1 align="center">ClickHouse Connector for Power BI</h1>
</p>
<br/>


## Introduction

This connector allows you to retrieve data from ClickHouse directly into Power BI for analysis and visualization.

## Features

- **Direct Query**: The connector supports Direct Query mode, allowing you to work with large datasets in real-time.
- **ODBC Driver Configuration**: Customize the ODBC driver settings to meet your specific requirements.

## Installation


1. Donwload and install [ClickHouse ODBC driver](https://github.com/ClickHouse/clickhouse-odbc).
2. Create the following directory for the custom connector  "[Documents]\Microsoft Power BI Desktop\Custom Connectors directory"
2. Download the latest release of the Power BI Connector for ClickHouse from the [Releases section](https://github.com/ClickHouse/power-bi-clickhouse/releases) and place it in the directory you just created.
2. Enable unsigned connectors loading - File -> Options and settings -> Options -> Security -> Data Extensions -> Allow any extension to load without warning or validation.
3. Click on "Get Data" and search for "ClickHouseODBCConnector."
4. Enter the required connection details, such as server name, port, database name, and optional connection options.
5. Enter your user name and password.
5. Choose the desired data retrieval mode: Import or Direct Query.
6. Click "OK" to establish the connection and start working with ClickHouse data in Power BI.

## Documentation

For more information about the ClickHouseODBCConnector functions, configuration options, and usage examples, refer to the [official documentation](https://clickhouse.com/docs/en/integrations/powerbi).

## Support and Feedback

If you encounter any issues or have feedback regarding the Power BI Connector for ClickHouse, please [submit an issue on GitHub](https://github.com/ClickHouse/power-bi-clickhouse/issues).
